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

+ (instancetype) defaultManager
{
    static RHEVindsidenAPIClient *_defaultManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultManager = [[RHEVindsidenAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
    });
    return _defaultManager;
}



- (instancetype) initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];

    if ( nil != self ) {
        self.responseSerializer = [AFXMLParserSerializer serializer];

        RHEVindsidenAPIClient __weak *blocksafeSelf = self;
        [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_STATUS_CHANGED object:blocksafeSelf userInfo:@{@"AFNetworkReachabilityStatus": @(status)}];
        }];
    }

    return self;
}


- (void)fetchStations:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(NSError *error))errorBlock
{
    [self GET:@"/xml.aspx"
        parameters:nil
           success:^(NSHTTPURLResponse *urlResponse, id response) {
               VindsidenStationClient *parser = [[VindsidenStationClient alloc] initWithParser:response];
               NSArray *parsedStations = [parser parse];

               if ( completionBlock ) {
                   completionBlock( YES, parsedStations);
               }
           }
           failure:^(NSError *error) {
               DLOG(@"Fetching failed: %@", error);
               if ( completionBlock ) {
                   completionBlock( NO, nil );
               }

               if ( NO == self.background && errorBlock ) {
                   errorBlock( error );
               }
           }
     ];
}


- (void)fetchStationsPlotsForStation:(NSNumber *)station completion:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(BOOL cancelled, NSError *error))errorBlock
{
    NSParameterAssert(station);

    DLOG(@"IS BACKGROUND: %d",self.background);

    __weak __block NSURLSessionDataTask *task = [self GET:@"/xml.aspx"
       parameters:@{@"id": station, @"hours": @(kPlotHistoryHours+1)}
          success:^(NSHTTPURLResponse *urlResponse, id response) {
              VindsidenPlotClient *parser = [[VindsidenPlotClient alloc] initWithParser:response];
              NSArray *parsedPlots = [parser parse];

              if ( completionBlock ) {
                  completionBlock( YES, parsedPlots);
              }
          }
          failure:^(NSError *error) {
              if ( completionBlock ) {
                  completionBlock( NO, nil );
              }

              BOOL isCancelled = NO;
              NSURLSessionDataTask __strong *strongTask = task;
              if ( strongTask ) {
                  isCancelled = (strongTask.state == NSURLSessionTaskStateCanceling);
              }
              DLOG(@"%d - %d", isCancelled, strongTask.state);

              if ( NO == self.background && errorBlock ) {
                  errorBlock( isCancelled, error );
              }
          }
     ];
}


@end
