//
//  RHEVindsidenAPIClient.h
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "AFHTTPClient.h"

extern NSString * const NETWORK_STATUS_CHANGED;

@interface RHEVindsidenAPIClient : AFHTTPClient

@property (nonatomic, assign) BOOL background;

+ (instancetype)defaultManager;

- (void)fetchStations:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(NSError *error))errorBlock;
- (void)fetchStationsPlotsForStation:(NSNumber *)station completion:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(BOOL cancelled, NSError *error))errorBlock;

@end
