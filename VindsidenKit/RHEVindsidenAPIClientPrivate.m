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

#import <VindsidenKit/VindsidenKit-Swift.h>
#import "RHEVindsidenAPIClientPrivate.h"
#import "VindsidenStationClient.h"
#import "VindsidenPlotClient.h"

#define kPlotHistoryHours 5

NSString * const NETWORK_STATUS_CHANGED = @"NetworkStatus_changed";
NSString *const kBaseURL = @"http://vindsiden.no/";


@implementation RHEVindsidenAPIClientPrivate
{
    NSTimeInterval __block _imageLastUpdated;
}

+ (instancetype) defaultManager
{
    static RHEVindsidenAPIClientPrivate *_defaultManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultManager = [[RHEVindsidenAPIClientPrivate alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
    });
    return _defaultManager;
}



- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];

    if ( nil != self ) {
        self.responseSerializer = [AFXMLParserResponseSerializer serializer];
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
               [Logger DLOG:[NSString stringWithFormat:@"Fetching failed: %@", error] file:@"" function:@(__PRETTY_FUNCTION__) line:__LINE__];

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

    [Logger DLOG:[NSString stringWithFormat:@"IS BACKGROUND: %d", self.background] file:@"" function:@(__PRETTY_FUNCTION__) line:__LINE__];

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

              if ( NO == self.background && errorBlock ) {
                  errorBlock( isCancelled, error );
              }
          }
     ];
}


@end
