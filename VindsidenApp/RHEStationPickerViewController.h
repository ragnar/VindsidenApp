//
//  RHEStationPickerViewController.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 14.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RHEStationPickerDelegate;

@interface RHEStationPickerViewController : UITableViewController <NSFetchedResultsControllerDelegate>


@property (weak, nonatomic) id<RHEStationPickerDelegate> delegate;

- (IBAction)done:(id)sender;

@end


@protocol RHEStationPickerDelegate <NSObject>

- (void)rheStationPickerDidFinish:(RHEStationPickerViewController *)controller;

@end
