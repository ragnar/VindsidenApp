//
//  RHCNavigationViewController.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 04.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCNavigationViewController.h"

@interface RHCNavigationViewController ()

@end

@implementation RHCNavigationViewController


- (NSUInteger)supportedInterfaceOrientations
{
    if ( [self.topViewController isKindOfClass:NSClassFromString(@"RHEWebCamViewController")] ) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}


@end
