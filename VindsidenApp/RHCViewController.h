//
//  RHCViewController.h
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RHEStationDetailsViewController.h"
#import "RHEWebCamViewController.h"
#import "RHCSettingsViewController.h"



@interface RHCViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, RHEStationDetailsDelegate, RHEWebCamImageViewDelegate, RHCSettingsDelegate>


- (void)updateContentWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end

