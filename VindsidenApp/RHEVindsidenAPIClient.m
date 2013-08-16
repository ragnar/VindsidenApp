//
//  RHEVindsidenAPIClient.m
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <AFNetworking.h>

#import "RHEVindsidenAPIClient.h"
#import "VindsidenStationClient.h"
#import "VindsidenPlotClient.h"

NSString * const NETWORK_STATUS_CHANGED = @"NetworkStatus_changed";
NSString *const kBaseURL = @"http://vindsiden.no/";


@implementation RHEVindsidenAPIClient
{
    NSTimeInterval __block _imageLastUpdated;
}

+ (id) defaultManager
{
    static RHEVindsidenAPIClient *_defaultManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultManager = [[RHEVindsidenAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
    });
    return _defaultManager;
}



- (id) initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];

    if ( nil != self ) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [self registerHTTPOperationClass:[AFXMLRequestOperation class]];
        [self setParameterEncoding:AFFormURLParameterEncoding];

        RHEVindsidenAPIClient __weak *blocksafeSelf = self;
        [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_STATUS_CHANGED object:blocksafeSelf userInfo:@{@"AFNetworkReachabilityStatus": @(status)}];
        }];
    }

    return self;
}


- (void)fetchStations:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(NSError *error))errorBlock
{
    [self getPath:@"/xml.aspx"
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id response) {
               VindsidenStationClient *parser = [[VindsidenStationClient alloc] initWithData:response];
               NSArray *parsedStations = [parser parse];

               if ( completionBlock ) {
                   completionBlock( YES, parsedStations);
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               DLOG(@"Fetching failed: %@", error);
               if ( completionBlock ) {
                   completionBlock( NO, nil );
               }

               if ( errorBlock ) {
                   errorBlock( error );
               }
           }
     ];
}


- (void)fetchStationsPlotsForStation:(NSNumber *)station completion:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(BOOL cancelled, NSError *error))errorBlock
{
    NSParameterAssert(station);

    [self getPath:@"/xml.aspx"
       parameters:@{@"id": station, @"hours": @kPlotHistoryHours}
          success:^(AFHTTPRequestOperation *operation, id response) {
              VindsidenPlotClient *parser = [[VindsidenPlotClient alloc] initWithData:response];
              NSArray *parsedPlots = [parser parse];

              if ( completionBlock ) {
                  completionBlock( YES, parsedPlots);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if ( completionBlock ) {
                  completionBlock( NO, nil );
              }

              if ( errorBlock ) {
                  errorBlock( [operation isCancelled], error );
              }
          }
     ];
}


- (void)cancelFetchStationPlotsForStation:(NSNumber *)station
{
    NSURL *pathToBeMatched = [[self requestWithMethod:@"GET" path:@"/xml.aspx" parameters:@{@"id": station, @"hours": @kPlotHistoryHours}] URL];

    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            continue;
        }

        BOOL hasMatchingPath = [[[(AFHTTPRequestOperation *)operation request] URL] isEqual:pathToBeMatched];

        if (hasMatchingPath) {
            DLOG(@"%@", [[(AFHTTPRequestOperation *)operation request] URL]);
            [operation cancel];
        }
    }
}


- (void)fetchWebCamImageForURL:(NSURL *)url ignoreFetchLimit:(BOOL)ignore success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure
{
    if ( NO == ignore ) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

        @synchronized(self) {
            if (  (now - 5*60) < _imageLastUpdated ) {
                return;
            }
            _imageLastUpdated = [[NSDate date] timeIntervalSince1970];
        }
    }

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPShouldHandleCookies:NO];
    [urlRequest setHTTPShouldUsePipelining:YES];
    [urlRequest addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    AFImageRequestOperation *requestOperation = [AFImageRequestOperation imageRequestOperationWithRequest:urlRequest
                                                                                     imageProcessingBlock:nil
                                                                                                  success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, UIImage *image) {
                                                                                                      if ( success ) {
                                                                                                          success(image);
                                                                                                      }
                                                                                                  }
                                                                                                  failure:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, NSError *error) {
                                                                                                      if ( failure ) {
                                                                                                          failure(error);
                                                                                                      }
                                                                                                  }
                                                 ];

    [self enqueueHTTPRequestOperation:requestOperation];
}

@end
