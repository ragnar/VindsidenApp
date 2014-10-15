//
//  RHCViewController.h
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RHEStationDetailsViewController.h"


@interface RHCViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, RHEStationDetailsDelegate, RHCSettingsDelegate>


- (void)updateContentWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (void)scrollToStation:(CDStation *)station;

@end

