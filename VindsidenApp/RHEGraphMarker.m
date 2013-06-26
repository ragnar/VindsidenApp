//
//  RHEGraphMarker.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 20.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import "RHEGraphMarker.h"
#import "CDPlot.h"
#import "CDStation.h"

#import "NSNumber+Convertion.h"

extern CGFloat DegreesToRadians(CGFloat degrees);
extern CGFloat RadiansToDegrees(CGFloat radians);


@interface RHEGraphMarker ()

@property (strong, nonatomic) UILabel *label;
@property (assign, nonatomic) CGFloat originX;

@property (assign, nonatomic) CGFloat markerMinY;
@property (assign, nonatomic) CGFloat markerAvgY;
@property (assign, nonatomic) CGFloat markerMaxY;

@end


@implementation RHEGraphMarker


@synthesize label = _label;
@synthesize originX = _originX;
@synthesize markerMinY = _markerMinY;
@synthesize markerAvgY = _markerAvgY;
@synthesize markerMaxY = _markerMaxY;

@synthesize minX = _minX;
@synthesize maxX = _maxX;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];

        self.originX = -100;
        self.label = [[UILabel alloc] initWithFrame:CGRectMake( self.originX, -40.0, 200.0, 30)];
        self.label.alpha = 0.85;
        self.label.backgroundColor = RGBCOLOR( 71.0, 63.0, 58.0); //[UIColor blackColor];
        self.label.clipsToBounds = NO;
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
        self.label.textAlignment = NSTextAlignmentCenter;

        [self addSubview:self.label];

        self.label.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.label.layer.shadowOffset = CGSizeMake( 1, 2);
        self.label.layer.shadowOpacity = 0.75;
        self.label.layer.shadowRadius = 2.5;
        self.label.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.label.bounds].CGPath;
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextBeginTransparencyLayer( context, NULL);

    CGContextSetAllowsAntialiasing( context, true);
    CGContextSetShadowWithColor( context, CGSizeMake(0.0, 2.0), 2.0, [UIColor colorWithWhite:0.0 alpha:0.25].CGColor);

    [[UIColor blackColor] set];
    CGContextSetLineWidth( context, 1);

    CGContextBeginPath(context);
    CGContextMoveToPoint( context, CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint( context, CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextDrawPath( context, kCGPathStroke);

    CGMutablePathRef path = CGPathCreateMutable();
    CGContextSetFillColorWithColor( context, [COLOR_MIN CGColor] );
    CGPathAddArc( path, NULL, CGRectGetMidX(rect), _markerMinY, 4, DegreesToRadians(-90), DegreesToRadians(360), 0);
    CGContextAddPath( context, path);
    CGContextFillPath( context);
    CGPathRelease( path);

    path = CGPathCreateMutable();
    CGContextSetFillColorWithColor( context, [COLOR_AVG CGColor] );
    CGPathAddArc( path, NULL, CGRectGetMidX(rect), _markerAvgY, 4, DegreesToRadians(-90), DegreesToRadians(360), 0);
    CGContextAddPath( context, path);
    CGContextFillPath( context);
    CGPathRelease( path);

    path = CGPathCreateMutable();
    CGContextSetFillColorWithColor( context, [COLOR_MAX CGColor] );
    CGPathAddArc( path, NULL, CGRectGetMidX(rect), _markerMaxY, 4, DegreesToRadians(-90), DegreesToRadians(360), 0);
    CGContextAddPath( context, path);
    CGContextFillPath( context);
    CGPathRelease( path);

    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
}


- (void)updateWithPlot:(CDPlot *)plot
{
    SpeedConvertion unit = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUnit"];

    self.label.text = [NSString stringWithFormat:NSLocalizedString(@"GRAPH_MARKER_POPUP", @"Gust: %@, Avg: %@, Speed: %@"),
                       [[self numberFormatter] stringFromNumber:@([plot.windMax speedConvertionTo:unit])],
                       [[self numberFormatter] stringFromNumber:@([plot.windAvg speedConvertionTo:unit])],
                       [[self numberFormatter] stringFromNumber:@([plot.windMin speedConvertionTo:unit])]];

    NSDictionary *fontAtts = @{NSFontAttributeName : self.label.font};
    CGRect labelBounds = [self.label.text boundingRectWithSize:CGSizeMake( 300.0, 30.0)
                                                            options:NSStringDrawingTruncatesLastVisibleLine
                                                  attributes:fontAtts
                                                     context:nil];

    CGRect lf = self.label.frame;
    lf.size.width = CGRectGetWidth(labelBounds);
    lf.size.width += 6;
    lf.size.height = 30.0;
    CGFloat sw = CGRectGetMaxX(self.superview.bounds);
    CGFloat center = (CGRectGetWidth(lf)/2);

    if ( sw == 0 ) {
        lf.origin.x = -1*center;
    } else if ( self.frame.origin.x < center ) {
        lf.origin.x = (-1*center) - (self.frame.origin.x-center);
    } else if ( self.frame.origin.x + center > sw ) {
        lf.origin.x = (sw-self.frame.origin.x) - (center*2);
    } else {
        lf.origin.x = -1*center;
    }

    self.label.frame = lf;

    self.label.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.label.layer.shadowOffset = CGSizeMake( 1, 2);
    self.label.layer.shadowOpacity = 0.75;
    self.label.layer.shadowRadius = 2.5;
    self.label.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.label.bounds].CGPath;
}


- (void)updateMarksWithMin:(CGFloat)min avg:(CGFloat)avg max:(CGFloat)max
{
    _markerMinY = min - self.frame.origin.y;
    _markerAvgY = avg - self.frame.origin.y;
    _markerMaxY = max - self.frame.origin.y;
    [self setNeedsDisplay];
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
