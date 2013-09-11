//
//  RHEStationDetailsViewController.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 16.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RHEWebCamViewController.h"

@protocol RHEStationDetailsDelegate;

@class CDStation;


@interface RHEStationDetailsViewController : UITableViewController <RHEWebCamImageViewDelegate>


@property (weak, nonatomic) id<RHEStationDetailsDelegate> delegate;
@property (strong, nonatomic) CDStation *station;

- (IBAction)done:(id)sender;
- (IBAction)gotoYR:(id)sender;
- (IBAction)showMap:(id)sender;
- (IBAction)showCamera:(id)sender;

@end


@protocol RHEStationDetailsDelegate <NSObject>

- (void) rheStationDetailsViewControllerDidFinish:(RHEStationDetailsViewController *)controller;

@end