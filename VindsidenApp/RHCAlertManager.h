//
//  RHCAlertManager.h
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18.06.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RHCAlertManager : NSObject

+ (id) defaultManager;
- (id) init;

- (void)showNetworkError:(NSError *)error;

@end
