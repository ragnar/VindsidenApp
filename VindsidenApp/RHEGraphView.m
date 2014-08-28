//
//  RHEGraphView.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 16.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import "RHEGraphView.h"
#import "RHEGraphMarker.h"
#import "DrawArrow.h"

#import "NSNumber+Convertion.h"

#import "CDPlot.h"

@import VindsidenKit;

const NSInteger kMaxSpeedLines = 8;
const NSInteger kMinSpeedLines = 3;

@interface RHEGraphView ()

@property (assign, nonatomic) CGFloat minX;
@property (assign, nonatomic) CGFloat minY;
@property (assign, nonatomic) CGFloat maxX;
@property (assign, nonatomic) CGFloat maxY;

@property (strong, nonatomic) NSDate *earliestDate;
@property (strong, nonatomic) NSDate *latestDate;
@property (strong, nonatomic) NSDate *absoluteStartDate;
@property (strong, nonatomic) NSDate *absoluteEndDate;

@property (assign, nonatomic) NSTimeInterval totMinutes;
@property (assign, nonatomic) CGFloat stepX;

@property (strong, nonatomic) RHEGraphMarker *marker;

- (void)drawGridInContext:(CGContextRef)context;
- (void)drawHourLines:(NSInteger)hours inContext:(CGContextRef)context;
- (void)drawHourText:(NSDate *)startDate numHours:(NSInteger)hours inContext:(CGContextRef)context;
- (void)drawSpeedLines:(CGContextRef)context;
- (void)drawSpeedText:(CGContextRef)context;
- (void)drawGraphLines:(NSDate *)startDate minutes:(NSTimeInterval)totMinutes maxValue:(CGFloat)plotMaxValue inContext:(CGContextRef)context;
- (void)drawWindArrows:(NSDate *)startDate minutes:(NSTimeInterval)totMinutes inContext:(CGContextRef)context;

- (CGFloat)snapToNearestPlot:(CGFloat)touchX;
- (CDPlot *)plotAtMarkerX:(CGFloat)touchX;
- (NSInteger)hourComponent:(NSDate *)date;
- (NSDate *)absoluteDate:(NSDate *)date isStart:(BOOL)isStart;
- (NSInteger)hours;
- (CGFloat)plotMaxValue;

- (CGFloat)YForMinPlot:(CDPlot *)plot;
- (CGFloat)YForAvgPlot:(CDPlot *)plot;
- (CGFloat)YForMaxPlot:(CDPlot *)plot;

@end


@implementation RHEGraphView

@synthesize plots = _plots;
@synthesize minX = _minX;
@synthesize maxX = _maxX;
@synthesize minY = _minY;
@synthesize maxY = _maxY;

@synthesize earliestDate = _earliestDate;
@synthesize latestDate = _latestDate;
@synthesize absoluteStartDate = _absoluteStartDate;
@synthesize absoluteEndDate = _absoluteEndDate;
@synthesize totMinutes = _totMinutes;
@synthesize stepX = _stepX;

@synthesize marker = _marker;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor redColor];
    }

    return self;
}


- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self ) {
        self.backgroundColor = [UIColor whiteColor];
        _minX = 30.0;
        _minY = 20.0;
        _maxX = 280.0;
        _maxY = 160.0;

        UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(viewLongPressed:)];
        [self addGestureRecognizer:gesture];
    }

    return self;
}


- (void) viewIsUpdated
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.marker.alpha = 0.0;
                     } 
                     completion:^(BOOL finished) {
                         [self.marker removeFromSuperview];
                         self.marker = nil;
                     }
     ];
}


- (void) setPlots:(NSArray *)plots
{
    _plots = plots;

    if ( [_plots count] ) {
        self.earliestDate = [[plots lastObject] valueForKeyPath:@"plotTime"];
        self.latestDate = [[plots[0] valueForKeyPath:@"plotTime"] dateByAddingTimeInterval:3600];
        self.absoluteStartDate = [self absoluteDate:self.earliestDate isStart:YES];
        self.absoluteEndDate = [self absoluteDate:self.latestDate isStart:NO];

        self.totMinutes = ([self.absoluteEndDate timeIntervalSinceDate:self.absoluteStartDate]/60);
    } else {
        self.earliestDate = nil;
        self.latestDate = nil;
        self.absoluteStartDate = nil;
        self.absoluteEndDate = nil;
        self.totMinutes = 0;
    }

    [self viewIsUpdated];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    self.maxX = self.frame.size.width - 10.0;
    self.maxY = self.frame.size.height - 40.0;
    self.stepX = (_maxX-_minX)/self.totMinutes;
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    [self drawSpeedLines:context];
    [self drawSpeedText:context];
    [self drawGridInContext:context];

    if ( [self.plots count] < 2 ) {
        [self drawHourLines:kPlotHistoryHours inContext:context];
        [self drawHourText:[[NSDate date] dateByAddingTimeInterval:-1*3600*kPlotHistoryHours] numHours:kPlotHistoryHours inContext:context];
        CGContextRestoreGState(context);
        return;
    }

    [self drawHourLines:[self hours] inContext:context];
    [self drawHourText:self.earliestDate numHours:[self hours] inContext:context];
    [self drawGraphLines:self.absoluteStartDate minutes:self.totMinutes maxValue:[self plotMaxValue] inContext:context];
    [self drawWindArrows:self.absoluteStartDate minutes:self.totMinutes inContext:context];
}


- (void)drawGridInContext:(CGContextRef)context
{
    CGContextSaveGState(context);
    CGContextBeginPath(context);

    CGContextSetLineWidth( context, 1.0);
    CGContextSetAllowsAntialiasing( context, NO);

    CGContextMoveToPoint( context, _minX, _maxY);
    CGContextAddLineToPoint( context, _maxX, _maxY);

    CGContextMoveToPoint( context, _minX, _minY-5);
    CGContextAddLineToPoint( context, _minX, _maxY);

    CGContextClosePath(context);
    CGContextDrawPath( context, kCGPathStroke);
    CGContextRestoreGState(context);
}


- (void)drawHourLines:(NSInteger)hours inContext:(CGContextRef)context
{
    CGContextSaveGState(context);
    CGContextSetLineWidth( context, 1.0);
    CGContextSetAllowsAntialiasing( context, NO);
    CGContextBeginPath(context);

    for ( CGFloat i = 0; i <= hours; i+=0.25 ) {
        NSInteger lineLenght = ( 0 == fmod(i, 1) ? 5 : 3);
        CGFloat x = ceil(_minX + (i*((_maxX-_minX)/hours)));
        CGContextMoveToPoint( context, x, _maxY);
        CGContextAddLineToPoint( context, x, _maxY+lineLenght);
    }

    CGContextClosePath(context);
    CGContextDrawPath( context, kCGPathStroke);
    CGContextRestoreGState(context);
}


- (void)drawHourText:(NSDate *)startDate numHours:(NSInteger)hours inContext:(CGContextRef)context
{
    CGContextSaveGState(context);

    CGContextSetAllowsAntialiasing( context, YES);

    NSDictionary *drawAttr = @{ NSFontAttributeName : [UIFont systemFontOfSize:10.0]};
    CGRect labelBounds = CGRectZero;

    for ( NSInteger i = 0; i <= hours; i++ ) {
        CGFloat x = _minX + (i*((_maxX-_minX)/hours));
        NSString *hs = [NSString stringWithFormat:@"%02ld", (long)[self hourComponent:[startDate dateByAddingTimeInterval:3600*i]]];
        labelBounds = [hs boundingRectWithSize:CGSizeMake( 40.0, 21.0)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:drawAttr
                                       context:nil];

        [hs drawAtPoint:CGPointMake( x-ceil(CGRectGetWidth(labelBounds)/2), _maxY+5) withAttributes:drawAttr];
    }

    CGContextRestoreGState(context);
}


- (void) drawSpeedLines:(CGContextRef)context
{
    CGContextSaveGState(context);

    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];
    CGFloat plotMaxValue = ceil([[self.plots valueForKeyPath:@"@max.windMax"] speedConvertionTo:unit]+1);
    NSInteger totSteps = MIN( kMaxSpeedLines, plotMaxValue);
    totSteps = MAX( kMinSpeedLines, totSteps);
    CGFloat plotStep = (_maxY-_minY)/totSteps;

    CGContextSetAllowsAntialiasing( context, NO);
    CGContextSetLineWidth( context, 1.0);

    CGContextBeginPath(context);

    for ( CGFloat y = _maxY; y >= _minY; y=ceil(y-plotStep)) {
        CGContextMoveToPoint( context, _minX - 4, y);
        CGContextAddLineToPoint( context, _minX, y);
    }

    CGContextClosePath(context);
    CGContextDrawPath( context, kCGPathStroke);

    CGContextBeginPath(context);

    for ( CGFloat y = ceil(_maxY-plotStep); y >= _minY; y=ceil(y-plotStep)) {
        CGContextMoveToPoint( context, _minX, y);
        CGContextAddLineToPoint( context, _maxX, y);
    }

    [[UIColor lightGrayColor] set];

    CGFloat lengths[] = {2.0, 3.0};
    CGContextSetLineDash( context, 0.0, lengths, 2);
    CGContextDrawPath( context, kCGPathStroke);

    CGContextRestoreGState(context);
}


- (void)drawSpeedText:(CGContextRef)context
{
    CGContextSaveGState(context);

    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];
    CGFloat plotMaxValue = ceil([[self.plots valueForKeyPath:@"@max.windMax"] speedConvertionTo:unit]+1);
    NSInteger totSteps = MIN( kMaxSpeedLines, plotMaxValue);
    totSteps = MAX( kMinSpeedLines, totSteps);

    CGFloat plotStep = (_maxY-_minY)/totSteps;

    CGContextSetAllowsAntialiasing( context, YES);

    NSDictionary *drawAttr = @{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:10.0]};
    CGRect labelBounds = CGRectZero;

    NSInteger i = 0;
    for ( CGFloat y = _maxY; y >= _minY; y=ceil(y-plotStep)) {
        NSString *hs = [[self speedFormatter] stringFromNumber:@(i*(plotMaxValue/totSteps))];

        labelBounds = [hs boundingRectWithSize:CGSizeMake( 40.0, 21.0)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:drawAttr
                                       context:nil];

        [hs drawAtPoint:CGPointMake( _minX-CGRectGetWidth(labelBounds)-5, y-(CGRectGetHeight(labelBounds)/2) ) withAttributes:drawAttr];
        i++;
    }

    NSString *unitName = [NSNumber shortUnitNameString:[[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"]];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentLeft];

    drawAttr = @{
                 NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:10.0],
                 NSParagraphStyleAttributeName : paragraphStyle
                 };
    labelBounds = [unitName boundingRectWithSize:CGSizeMake( 40.0, 21.0)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:drawAttr
                                   context:nil];

    labelBounds.origin.x = _minX;
    labelBounds.origin.y = _minY - 18;
    [unitName drawInRect:labelBounds withAttributes:drawAttr];

    unitName = @"vindsiden.no";
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentRight];

    drawAttr = @{
                 NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
                 NSParagraphStyleAttributeName : paragraphStyle,
                 NSForegroundColorAttributeName : [UIColor lightGrayColor]
                 };
    labelBounds = [unitName boundingRectWithSize:CGSizeMake( 140.0, 21.0)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:drawAttr
                                         context:nil];

    labelBounds.origin.x = _maxX - CGRectGetWidth(labelBounds);
    labelBounds.origin.y = _minY - 18;
    [unitName drawInRect:labelBounds withAttributes:drawAttr];

    CGContextRestoreGState(context);
}


- (void)drawGraphLines:(NSDate *)startDate minutes:(NSTimeInterval)totMinutes maxValue:(CGFloat)plotMaxValue inContext:(CGContextRef)context
{
    CGContextSaveGState(context);

    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];

    CGMutablePathRef pathMin = CGPathCreateMutable();
    CGMutablePathRef pathAvg = CGPathCreateMutable();
    CGMutablePathRef pathMax = CGPathCreateMutable();

    CDPlot *firstPlot = (self.plots)[0];
    NSTimeInterval interval = [firstPlot.plotTime timeIntervalSinceDate:startDate]/60;
    CGFloat x = ceil(_minX + (interval*self.stepX));

    CGContextSetLineWidth( context, 3);
    CGContextSetAllowsAntialiasing( context, YES);
    CGContextBeginPath(context);

    CGContextSetLineJoin( context, kCGLineJoinRound);
    CGContextSetLineCap( context, kCGLineCapRound);
    CGContextSetShadowWithColor( context, CGSizeMake(0.0, 2.0), 2.0, [UIColor colorWithWhite:0.0 alpha:0.25].CGColor);

    for ( CDPlot *plot in self.plots ) {
        CGFloat rMax = [plot.windMax speedConvertionTo:unit];
        CGFloat yMax = _maxY - ((rMax / plotMaxValue) * (_maxY - _minY));

        CGFloat rMin = [plot.windMin speedConvertionTo:unit];
        CGFloat yMin = _maxY - ((rMin / plotMaxValue) * (_maxY - _minY));

        CGFloat rAvg = [plot.windAvg speedConvertionTo:unit];
        CGFloat yAvg = _maxY - ((rAvg / plotMaxValue) * (_maxY - _minY));

        if ( [plot isEqual:(self.plots)[0]] ) {
            CGPathMoveToPoint(pathMax, NULL, x, yMax);
            CGPathMoveToPoint(pathAvg, NULL, x, yAvg);
            CGPathMoveToPoint(pathMin, NULL, x, yMin);
            continue;
        }
        else {
            NSTimeInterval interval = [plot.plotTime timeIntervalSinceDate:startDate]/60;
            x = ceil(_minX + (interval*self.stepX));

            CGPathAddLineToPoint(pathMax, NULL, x, yMax);
            CGPathAddLineToPoint(pathAvg, NULL, x, yAvg);
            CGPathAddLineToPoint(pathMin, NULL, x, yMin);
        }
    }

    [COLOR_MIN set];
    CGContextAddPath( context, pathMin);
    CGContextDrawPath(context, kCGPathStroke);

    [COLOR_AVG set];
    CGContextAddPath( context, pathAvg);
    CGContextDrawPath(context, kCGPathStroke);

    [COLOR_MAX set];
    CGContextAddPath( context, pathMax);
    CGContextDrawPath(context, kCGPathStroke);

    CGPathRelease(pathMin);
    CGPathRelease(pathAvg);
    CGPathRelease(pathMax);
    
    CGContextRestoreGState(context);
}


- (void)drawWindArrows:(NSDate *)startDate minutes:(NSTimeInterval)totMinutes inContext:(CGContextRef)context
{
    CGContextSaveGState(context);

    CGFloat calcStep = (_maxX-_minX)/totMinutes;
    CGFloat x = 0.0;
    NSTimeInterval interval = 0.0;

    for ( CDPlot *plot in self.plots ) {
        interval = [plot.plotTime timeIntervalSinceDate:startDate]/60;
        x = ceil(_minX + (interval*calcStep));

        [[DrawArrow drawArrowAtAngle:[plot.windDir floatValue]
                            forSpeed:[plot.windAvg floatValue]
                         highlighted:0] drawAtPoint:CGPointMake(x-16, _maxY+10)];
    }

    CGContextRestoreGState(context);
}

#pragma mark -

- (void)viewLongPressed:(UILongPressGestureRecognizer *)gesture
{
    static CGFloat previousX = 0.0;

    if ( gesture.state == UIGestureRecognizerStateBegan ) {
        CGPoint point = [gesture locationInView:self];
        point.x = [self snapToNearestPlot:point.x];
        self.marker = [[RHEGraphMarker alloc] initWithFrame:CGRectMake( point.x-10, _minY, 20, _maxY-_minY)];
        self.marker.alpha = 0.0;
        self.marker.minX = self.minX;
        self.marker.maxX = self.maxX;
        [self addSubview:self.marker];

        CDPlot *plot = [self plotAtMarkerX:point.x];
        CGFloat min = [self YForMinPlot:plot];
        CGFloat avg = [self YForAvgPlot:plot];
        CGFloat max = [self YForMaxPlot:plot];

        CGRect frame = self.marker.frame;
        frame.origin.x = point.x - (frame.size.width/2);
        self.marker.frame = frame;

        [self.marker updateWithPlot:plot];
        [self.marker updateMarksWithMin:min avg:avg max:max];

        [UIView animateWithDuration:0.25
                         animations:^{
                             self.marker.alpha = 1.0;
                         }
         ];
    } else if ( gesture.state == UIGestureRecognizerStateChanged ) {
        CGPoint point = [gesture locationInView:self];
        point.x = [self snapToNearestPlot:point.x];
        if ( previousX == point.x ) {
            return;
        }
        previousX = point.x;
        CGRect frame = self.marker.frame;
        frame.origin.x = point.x - (frame.size.width/2);

        CDPlot *plot = [self plotAtMarkerX:point.x];
        CGFloat min = [self YForMinPlot:plot];
        CGFloat avg = [self YForAvgPlot:plot];
        CGFloat max = [self YForMaxPlot:plot];
    
        [UIView animateWithDuration:0.06
                         animations:^{
                             self.marker.frame = frame;
                             [self.marker updateWithPlot:plot];
                             [self.marker updateMarksWithMin:min avg:avg max:max];
                         }
         ];
    } else if ( gesture.state == UIGestureRecognizerStateEnded ) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.marker.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [self.marker removeFromSuperview];
                             self.marker = nil;
                         }
         ];
    }
}


- (CGFloat)YForMinPlot:(CDPlot *)plot
{
    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];
    CGFloat rMin = [plot.windMin speedConvertionTo:unit];
    CGFloat yMin = _maxY - ((rMin / [self plotMaxValue]) * (_maxY - _minY));

    return yMin;
}


- (CGFloat)YForAvgPlot:(CDPlot *)plot
{
    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];
    CGFloat rMin = [plot.windAvg speedConvertionTo:unit];
    CGFloat yMin = _maxY - ((rMin / [self plotMaxValue]) * (_maxY - _minY));
    
    return yMin;
}


- (CGFloat)YForMaxPlot:(CDPlot *)plot
{
    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];
    CGFloat rMin = [plot.windMax speedConvertionTo:unit];
    CGFloat yMin = _maxY - ((rMin / [self plotMaxValue]) * (_maxY - _minY));
    
    return yMin;
}


- (CGFloat)snapToNearestPlot:(CGFloat)touchX
{
    NSTimeInterval interval;
    CGFloat x = 0.0;

    for ( CDPlot *plot in self.plots ) {
        interval = [plot.plotTime timeIntervalSinceDate:self.absoluteStartDate]/60;
        x = ceil(_minX + (interval*self.stepX));
        if ( x <= touchX) {
            return x;
        }
    }
    return x;
}


- (CDPlot *)plotAtMarkerX:(CGFloat)touchX
{
    NSTimeInterval interval;
    CGFloat x = 0.0;

    for ( CDPlot *plot in self.plots ) {
        interval = [plot.plotTime timeIntervalSinceDate:self.absoluteStartDate]/60;
        x = ceil(_minX + (interval*self.stepX));
        if ( x == touchX) {
            return plot;
        }
    }
    return nil;
}


- (NSInteger)hourComponent:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *hourComponents = [gregorian components:(NSCalendarUnitHour) fromDate:date];

    return [hourComponents hour];
}


- (NSDate *)absoluteDate:(NSDate *)date isStart:(BOOL)isStart
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *inputComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour) fromDate:date];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:[inputComponents year]];
    [components setMonth:[inputComponents month]];
    [components setDay:[inputComponents day]];
    [components setHour:[inputComponents hour]];

    NSDate *outDate = [gregorian dateFromComponents:components];
    return  outDate;
}


- (NSInteger)hours
{
    return ([self.absoluteEndDate timeIntervalSinceDate:self.absoluteStartDate]/3600);
}


- (CGFloat)plotMaxValue
{
    SpeedConvertion unit = [[Datamanager sharedManager].sharedDefaults integerForKey:@"selectedUnit"];
    return ceil([[self.plots valueForKeyPath:@"@max.windMax"] speedConvertionTo:unit]+1);
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
    _numberformatter.minimumSignificantDigits = 1;
    [_numberformatter setNotANumberSymbol:@"—.—"];
    [_numberformatter setNilSymbol:@"—.—"];

    return _numberformatter;
}


@end
