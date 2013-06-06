//
//  NSNumber+Convertion.m
//  
//
//  Created by Ragnar Henriksen on 19.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "NSNumber+Convertion.h"
#import "NSNumber+Between.h"

@implementation NSNumber (Convertion)

- (CGFloat) speedConvertionTo:(SpeedConvertion)toUnit
{
    switch ( toUnit ) 
    {
        case SpeedConvertionToKnotsPerSecond:
            return [self floatValue] * 1.94384449;
            break;
        case SpeedConvertionToKilometersPerHour:
            return [self floatValue] * 3.6;
            break;
        case SpeedConvertionToMilesPerHour:
            return [self floatValue] * 2.2369363;
            break;
        case SpeedConvertionBeaufort:
            return [self speedInBeaufort];
            break;
        case SpeedConvertionToMetersPerSecond:
        default:
            return [self floatValue];
            break;
    }

    return [self floatValue];
}


- (CGFloat )speedInBeaufort
{
    NSNumber *knots = [NSNumber numberWithFloat:[self speedConvertionTo:SpeedConvertionToKnotsPerSecond]];

    if ( [knots isBetween:0 and:1.0] ) {
        return 0.0;
    } else if ( [knots isBetween:1.0 and:4.0] ) {
        return 1.0;
    } else if ( [knots isBetween:4.0 and:7.0] ) {
        return 2.0;
    } else if ( [knots isBetween:7.0 and:11.0] ) {
        return 3.0;
    } else if ( [knots isBetween:11.0 and:17.0] ) {
        return 4.0;
    } else if ( [knots isBetween:17.0 and:22.0] ) {
        return 5.0;
    } else if ( [knots isBetween:22.0 and:28.0] ) {
        return 6.0;
    } else if ( [knots isBetween:28.0 and:34.0] ) {
        return 7.0;
    } else if ( [knots isBetween:34.0 and:41.0] ) {
        return 8.0;
    } else if ( [knots isBetween:41.0 and:48.0] ) {
        return 8.0;
    } else if ( [knots isBetween:48.0 and:56.0] ) {
        return 10.0;
    } else if ( [knots isBetween:56.0 and:64.0] ) {
        return 11.0;
    }

    return 12.0;
}


+ (NSString *) longUnitNameString:(SpeedConvertion)unit
{
    switch ( unit ) 
    {
        case SpeedConvertionToKnotsPerSecond:
            return NSLocalizedString(@"Knots", nil);
            break;
        case SpeedConvertionToKilometersPerHour:
            return NSLocalizedString(@"Kilometers per hour", nil);
            break;
        case SpeedConvertionToMilesPerHour:
            return NSLocalizedString(@"Miles per hour", nil);
            break;
        case SpeedConvertionToMetersPerSecond:
        default:
            return NSLocalizedString(@"Meters per second", nil);
            break;
    }
    
    return NSLocalizedString(@"Meters per second", nil);
}

+ (NSString *) shortUnitNameString:(SpeedConvertion)unit
{
    switch ( unit ) 
    {
        case SpeedConvertionToKnotsPerSecond:
            return NSLocalizedString(@"kts", nil);
            break;
        case SpeedConvertionToKilometersPerHour:
            return NSLocalizedString(@"km/h", nil);
            break;
        case SpeedConvertionToMilesPerHour:
            return NSLocalizedString(@"miles/h", nil);
            break;
        case SpeedConvertionToMetersPerSecond:
        default:
            return NSLocalizedString(@"m/s", nil);
            break;
    }
    
    return NSLocalizedString(@"m/s", nil);
}


@end
