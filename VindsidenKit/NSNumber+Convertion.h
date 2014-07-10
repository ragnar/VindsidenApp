//
//  NSNumber+Convertion.h
//  
//
//  Created by Ragnar Henriksen on 19.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, SpeedConvertion)
{
    SpeedConvertionToMetersPerSecond = 1,
    SpeedConvertionToKnotsPerSecond,
    SpeedConvertionToKilometersPerHour,
    SpeedConvertionToMilesPerHour,
    SpeedConvertionBeaufort
};


@interface NSNumber (Convertion)

- (CGFloat) speedConvertionTo:(SpeedConvertion)toUnit;
- (CGFloat )speedInBeaufort;
+ (NSString *) longUnitNameString:(SpeedConvertion)unit;
+ (NSString *) shortUnitNameString:(SpeedConvertion)unit;

@end
