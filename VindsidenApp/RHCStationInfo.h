//
//  RHCStationInfo.h
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM( NSUInteger, StationViewTempKind)
{
    StationViewTempKindTemp = 0,
    StationViewTempKindChill
};


@class  CDPlot;

@interface RHCStationInfo : UIView

@property (nonatomic, assign) StationViewTempKind tempKind;

- (void)updateWithPlot:(CDPlot *)plot;

@end
