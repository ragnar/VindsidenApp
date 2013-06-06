//
//  RHEGraphMarker.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 20.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import <UIKit/UIKit.h>


#define COLOR_MIN RGBCOLOR( 208.0, 221.0, 0.0)
#define COLOR_AVG RGBCOLOR( 58.0, 217.0, 255.0)
#define COLOR_MAX RGBCOLOR( 255.0, 73.0, 62.0)


@class CDPlot;


@interface RHEGraphMarker : UIView

@property (assign, nonatomic) CGFloat minX;
@property (assign, nonatomic) CGFloat maxX;


- (void)updateWithPlot:(CDPlot *)plot;
- (void)updateMarksWithMin:(CGFloat)min avg:(CGFloat)avg max:(CGFloat)max;

@end
