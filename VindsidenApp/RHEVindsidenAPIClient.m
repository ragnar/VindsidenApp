//
//  RHEVindsidenAPIClient.m
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

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
        self.responseSerializer = [AFXMLParserResponseSerializer serializer];

        RHEVindsidenAPIClient __weak *blocksafeSelf = self;
        [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_STATUS_CHANGED object:blocksafeSelf userInfo:@{@"AFNetworkReachabilityStatus": @(status)}];
        }];
        [self.reachabilityManager startMonitoring];
    }

    return self;
}


- (void)fetchStations:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(NSError *error))errorBlock
{
    [self GET:@"/xml.aspx"
        parameters:nil
           success:^(NSURLSessionDataTask *task, id response) {
               VindsidenStationClient *parser = [[VindsidenStationClient alloc] initWithParser:response];
               NSArray *parsedStations = [parser parse];

               if ( completionBlock ) {
                   completionBlock( YES, parsedStations);
               }
           }
           failure:^(NSURLSessionDataTask *task, NSError *error) {
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

    [self GET:@"/xml.aspx"
       parameters:@{@"id": station, @"hours": @(kPlotHistoryHours+1)}
          success:^(NSURLSessionDataTask *task, id response) {
              VindsidenPlotClient *parser = [[VindsidenPlotClient alloc] initWithParser:response];
              NSArray *parsedPlots = [parser parse];

              if ( completionBlock ) {
                  completionBlock( YES, parsedPlots);
              }
          }
          failure:^(NSURLSessionDataTask *task, NSError *error) {
              if ( completionBlock ) {
                  completionBlock( NO, nil );
              }

              BOOL isCancelled = NO;
              DLOG(@"%d - %d", isCancelled, task.state);

              if ( NO == self.background && errorBlock ) {
                  errorBlock( isCancelled, error );
              }
          }
     ];
}


@end
