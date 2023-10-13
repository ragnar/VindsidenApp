//
//  RHCStationInfo.m
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "VindsidenApp-Swift.h"
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
    [super awakeFromNib];
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
    _windSpeed.text = [self windStringWithValue:[plot.windMin doubleValue]];
    _windGust.text = [self windStringWithValue:[plot.windMax doubleValue]];
    _windAverage.text = [self windStringWithValue:[plot.windAvg doubleValue]];
    _windBeaufort.text = (isnan([plot.windAvg floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f", [plot.windMin speedInBeaufort]]);
    _windDirection.text = (isnan([plot.windDir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f° (%@)", [plot.windDir floatValue], [plot windDirectionString]]);
    _tempAir.text = [self tempStringWithValue:[plot.tempAir doubleValue]];
}


- (NSNumberFormatter *)numberFormatter
{
    static NSNumberFormatter *_numberformatter = nil;
    if ( _numberformatter ) {
        return _numberformatter;
    }

    _numberformatter = [[NSNumberFormatter alloc] init];
    _numberformatter.numberStyle = NSNumberFormatterDecimalStyle;
    _numberformatter.maximumFractionDigits = 1;
    _numberformatter.minimumFractionDigits = 1;
    //_numberformatter.minimumSignificantDigits = 1;
    [_numberformatter setNotANumberSymbol:@"—.—"];
    [_numberformatter setNilSymbol:@"—.—"];

    return _numberformatter;
}


@end
