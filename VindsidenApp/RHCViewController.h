//
//  RHCViewController.h
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreData;
@import VindsidenKit;


@interface RHCViewController : UIViewController


- (void)updateContentWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (void)scrollToStation:(CDStation *)station;

@end

