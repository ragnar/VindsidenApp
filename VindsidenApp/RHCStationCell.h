//
//  RHCStationCell.h
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RHCStationInfo.h"

@class CDStation;
@class RHEGraphView;


@interface RHCStationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *stationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *updatedAtLabel;
@property (weak, nonatomic) IBOutlet RHCStationInfo *stationView;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet RHEGraphView *graphView;

@property (weak, nonatomic) CDStation *currentStation;

- (void)fetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)fetch;
- (void)displayPlots;
- (void)syncDisplayPlots;

@end
