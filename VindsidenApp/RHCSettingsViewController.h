//
//  RHCSettingsViewController.h
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 04.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RHCSettingsDelegate;

@interface RHCSettingsViewController : UITableViewController

@property (weak, nonatomic) id<RHCSettingsDelegate> delegate;

@end

@protocol RHCSettingsDelegate <NSObject>

- (void)rhcSettingsDidFinish:(RHCSettingsViewController *)controller;

@end