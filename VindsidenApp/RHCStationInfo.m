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
    _windDirection.text = (isnan([plot.windDir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f° (%@)", [plot.windDir floatValue], [plot windDirectionString]]);
    _tempAir.text = (isnan([plot.tempAir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ °C", [[self numberFormatter] stringFromNumber:plot.tempAir]]);
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
