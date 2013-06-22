//
//  RHCStationInfo.m
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//
#import "NSNumber+Convertion.h"
#import "NSNumber+Between.h"

#import "RHCStationInfo.h"
#import "CDPlot.h"


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
    self = [super initWithCoder:aDecoder];
    if ( self ) {
        [self initInfoLabels];
    }

    return self;
}


- (void)initInfoLabels
{
    CGFloat x = 75.0;
    CGFloat y = 8.0;
    CGFloat height = 14.0;
    CGFloat width = 85.0;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height)];
    [self addSubview:lbl];
    self.windSpeed = lbl;
    y += 30;

    lbl = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height)];
    [self addSubview:lbl];
    self.windGust = lbl;
    y += 30;

    lbl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [self addSubview:lbl];
    self.windDirection = lbl;

    x = 215.0;
    y = 8.0;

    lbl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [self addSubview:lbl];
    self.windAverage = lbl;
    y += 30;

    lbl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [self addSubview:lbl];
    self.windBeaufort = lbl;
    y += 30;

    lbl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [self addSubview:lbl];
    self.tempAir = lbl;

    [self resetInfoLabels];
}


- (void)resetInfoLabels
{
    for ( UILabel *l in @[self.windSpeed, self.windGust, self.windAverage, self.windBeaufort, self.windDirection, self.tempAir] ) {
        l.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
        l.backgroundColor = [UIColor clearColor];
        l.textAlignment = NSTextAlignmentRight;
        l.text = @"—.—";
    }
}


- (void)updateWithPlot:(CDPlot *)plot
{
    SpeedConvertion unit = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUnit"];

    _windSpeed.text = (isnan([plot.windMin floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ %@",  [[self numberFormatter] stringFromNumber:@([plot.windMin speedConvertionTo:unit])], [NSNumber shortUnitNameString:unit]]);
    _windGust.text = (isnan([plot.windMax floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ %@", [[self numberFormatter] stringFromNumber:@([plot.windMax speedConvertionTo:unit])], [NSNumber shortUnitNameString:unit]]);
    _windAverage.text = (isnan([plot.windAvg floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ %@", [[self numberFormatter] stringFromNumber:@([plot.windAvg speedConvertionTo:unit])], [NSNumber shortUnitNameString:unit]]);
    _windBeaufort.text = (isnan([plot.windAvg floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f", [plot.windMin speedInBeaufort]]);
    _windDirection.text = (isnan([plot.windDir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%0.0f° (%@)", [plot.windDir floatValue], [self windDirectionString:[plot.windDir floatValue]]]);
    _tempAir.text = (isnan([plot.tempAir floatValue]) ? @"—.—" : [NSString stringWithFormat:@"%@ °C", [[self numberFormatter] stringFromNumber:plot.tempAir]]);
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    [NSLocalizedString(@"LABEL_WIND_SPEED", @"Wind speed") drawAtPoint:CGPointMake( 20.0, 10.0) withFont:[UIFont fontWithName:@"DIN 1451 Std" size:11.0]];
    [NSLocalizedString(@"LABEL_WIND_GUST", @"Wind gust") drawAtPoint:CGPointMake( 20.0, 40.0) withFont:[UIFont fontWithName:@"DIN 1451 Std" size:11.0]];
    [NSLocalizedString(@"LABEL_WIND_DIR", @"Wind direction") drawAtPoint:CGPointMake( 20.0, 70.0) withFont:[UIFont fontWithName:@"DIN 1451 Std" size:11.0]];
    [NSLocalizedString(@"LABEL_WIND_AVG", @"Average") drawAtPoint:CGPointMake( 170.0, 10.0) withFont:[UIFont fontWithName:@"DIN 1451 Std" size:11.0]];
    [NSLocalizedString(@"LABEL_WIND_BEU", @"Beaufort") drawAtPoint:CGPointMake( 170.0, 40.0) withFont:[UIFont fontWithName:@"DIN 1451 Std" size:11.0]];
    [NSLocalizedString(@"Temp air", @"Temp air") drawAtPoint:CGPointMake( 170.0, 70.0) withFont:[UIFont fontWithName:@"DIN 1451 Std" size:11.0]];

    [RGBACOLOR( 0.0, 0.0, 0.0, 0.13) set];
    CGContextBeginPath(context);

    CGFloat y = 24.0;
    for ( int i = 0; i < 3; ++i ) {
        CGContextMoveToPoint(context, 20.0, y);
        CGContextAddLineToPoint(context, 160.0, y);

        CGContextMoveToPoint(context, 160.0, y);
        CGContextAddLineToPoint(context, 300.0, y);
        y += 30.0;
    }
    CGContextDrawPath(context, kCGPathStroke);

    CGContextRestoreGState(context);
}


- (NSString *) windDirectionString:(CGFloat)direction
{
    if ( direction > 360.0 || direction < 0 ) {
        direction = 0.0;
    }
    NSNumber *dir = [NSNumber numberWithFloat:direction];


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
    _numberformatter.maximumFractionDigits = 1;
    _numberformatter.minimumFractionDigits = 1;
    return _numberformatter;
}


@end
