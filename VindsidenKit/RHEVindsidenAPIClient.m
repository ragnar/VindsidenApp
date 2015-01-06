//
//  RHCVindsidenAPIClient.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15/12/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

#import "RHEVindsidenAPIClient.h"
#import "RHEVindsidenAPIClientPrivate.h"


@implementation RHEVindsidenAPIClient


+ (instancetype)defaultManager
{
    static RHEVindsidenAPIClient *_defaultManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultManager = [[RHEVindsidenAPIClient alloc] init];
    });

    return _defaultManager;
}


- (BOOL)background
{
    return [[RHEVindsidenAPIClientPrivate defaultManager] background];
}

- (NSOperationQueue *)operationQueue
{
    return [[RHEVindsidenAPIClientPrivate defaultManager] operationQueue];
}


- (void)setBackground:(BOOL)background
{
    [[RHEVindsidenAPIClientPrivate defaultManager] setBackground:background];
}


- (void)fetchStations:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(NSError *error))errorBlock
{
    [[RHEVindsidenAPIClientPrivate defaultManager] fetchStations:completionBlock error:errorBlock];
}


- (void)fetchStationsPlotsForStation:(NSNumber *)station completion:(void (^)(BOOL success, NSArray *stations))completionBlock error:(void (^)(BOOL cancelled, NSError *error))errorBlock
{
    [[RHEVindsidenAPIClientPrivate defaultManager] fetchStationsPlotsForStation:station completion:completionBlock error:errorBlock];
}


@end
