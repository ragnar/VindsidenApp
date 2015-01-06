//
//  RHCVindsidenAPIClient.h
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15/12/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NETWORK_STATUS_CHANGED;


@interface RHEVindsidenAPIClient : NSObject

@property (nonatomic, assign) BOOL background;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

+ (instancetype)defaultManager;

- (void)fetchStations:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(NSError *error))errorBlock;
- (void)fetchStationsPlotsForStation:(NSNumber *)station completion:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(BOOL cancelled, NSError *error))errorBlock;

@end
