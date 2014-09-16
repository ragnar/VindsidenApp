//
//  RHCAppDelegate.h
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RHCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (NSString *)applicationPrivateDocumentsDirectory;

@end
