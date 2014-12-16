//
//  RHCStationInfo.m
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCStationInfo.h"

@import VindsidenKit;

@interface RHCStationInfo ()

@property (weak, nonatomic) IBOutlet UILabel *windSpeed;
@property (weak, nonatomic) IBOutlet UILabel *windGust;
@property (weak, nonatomic) IBOutlet UILabel *windAverage;
@property (weak, nonatomic) IBOutlet UILabel *windDirection;
@property (weak, nonatomic) IBOutlet UILabel *windBeaufort;
@property (weak, nonatomic) IBOutlet UILabel *tempAir;

@end

@implementation RHCStationInfo


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    return [super initWithCoder:aDecoder];
}


- (void)awakeFromNib
{
    [self resetInfoLabels];
}

- (void)resetInfoLabels
{
    for ( UILabel *l in @[self.windSpeed, self.windGust, self.windAverage, self.windBeaufort, self.windDirection, self.tempAir] ) {
        l.text = @"—.—";
    }
}


- (void)updateWithPlot:(CDPlot *)plot
{
    SpeedConvertion unit = [[AppConfig sharedConfiguration].applicationUserDefaults integerForKey:@"selectedUnit"];

    _windSpeed.text = (isnan([plot.windMin floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ %@",  [[self numberFormatter] stringFromNumber:@([plot.windMin speedConvertionTo:unit])], [NSNumber shortUnitNameString:unit]]);
    _windGust.text = (isnan([plot.windMax floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ %@", [[self numberFormatter] stringFromNumber:@([plot.windMax speedConvertionTo:unit])], [NSNumber shortUnitNameString:unit]]);
    _windAverage.text = (isnan([plot.windAvg floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ %@", [[self numberFormatter] stringFromNumber:@([plot.windAvg speedConvertionTo:unit])], [NSNumber shortUnitNameString:unit]]);
    _windBeaufort.text = (isnan([plot.windAvg floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f", [plot.windMin speedInBeaufort]]);
    _windDirection.text = (isnan([plot.windDir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f° (%@)", [plot.windDir floatValue], [self windDirectionString:[plot.windDir floatValue]]]);
    _tempAir.text = (isnan([plot.tempAir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ °C", [[self numberFormatter] stringFromNumber:plot.tempAir]]);
}


- (NSString *) windDirectionString:(CGFloat)direction
{
    if ( direction > 360.0 || direction < 0 ) {
        direction = 0.0;
    }
    NSNumber *dir = @(direction);


    if ( [dir isBetween:0.0 and:11.25] || [dir isBetween:348.75 and:360.001]) {
        return NSLocalizedString(@"DIRECTION_N", @"N");
    } else if ( [dir isBetween:11.25 and:33.35] ) {
        return NSLocalizedString(@"DIRECTION_NNE", @"NNE");
    } else if ( [dir isBetween:33.75 and:56.25] ) {
        return NSLocalizedString(@"DIRECTION_NE", @"NE");
    } else if ( [dir isBetween:56.25 and:78.75] ) {
        return NSLocalizedString(@"DIRECTION_ENE", @"ENE");
    } else if ( [dir isBetween:78.75 and:101.25] ) {
        return NSLocalizedString(@"DIRECTION_E", @"E");
    } else if ( [dir isBetween:101.25 and:123.75] ) {
        return NSLocalizedString(@"DIRECTION_ESE", @"ESE");
    } else if ( [dir isBetween:123.75 and:146.25] ) {
        return NSLocalizedString(@"DIRECTION_SE", @"SE");
    } else if ( [dir isBetween:146.25 and:168.75] ) {
        return NSLocalizedString(@"DIRECTION_SSE", @"SSE");
    } else if ( [dir isBetween:168.75 and:191.25] ) {
        return NSLocalizedString(@"DIRECTION_S", @"S");
    } else if ( [dir isBetween:191.25 and:213.75] ) {
        return NSLocalizedString(@"DIRECTION_SSW", @"SSW");
    } else if ( [dir isBetween:213.75 and:236.25] ) {
        return NSLocalizedString(@"DIRECTION_SW", @"SW");
    } else if ( [dir isBetween:236.25 and:258.75] ) {
        return NSLocalizedString(@"DIRECTION_WSW", @"WSW");
    } else if ( [dir isBetween:258.75 and:281.25] ) {
        return NSLocalizedString(@"DIRECTION_W", @"W");
    } else if ( [dir isBetween:281.25 and:303.75] ) {
        return NSLocalizedString(@"DIRECTION_WNW", @"WNW");
    } else if ( [dir isBetween:303.75 and:326.25] ) {
        return NSLocalizedString(@"DIRECTION_NW", @"NW");
    } else if ( [dir isBetween:326.25 and:348.75] ) {
        return NSLocalizedString(@"DIRECTION_NNW", @"NNW");
    } else {
        return NSLocalizedString(@"DIRECTION_UKN", @"UKN");
    }
}


- (NSNumberFormatter *)numberFormatter
{
    static NSNumberFormatter *_numberformatter = nil;
    if ( _numberformatter ) {
        return _numberformatter;
    }

    _numberformatter = [[NSNumberFormatter alloc] init];
    _numberformatter.numberStyle = kCFNumberFormatterDecimalStyle;
    _numberformatter.maximumFractionDigits = 1;
    _numberformatter.minimumFractionDigits = 1;
    //_numberformatter.minimumSignificantDigits = 1;
    [_numberformatter setNotANumberSymbol:@"—.—"];
    [_numberformatter setNilSymbol:@"—.—"];

    return _numberformatter;
}


@end
