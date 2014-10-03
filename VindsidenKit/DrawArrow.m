//
//  DrawArrow.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 18.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "DrawArrow.h"

CGFloat DegreesToRadians(CGFloat degrees);
CGFloat RadiansToDegrees(CGFloat radians);

CGFloat DegreesToRadians(CGFloat degrees)
{
    return degrees * M_PI / 180;
}

CGFloat RadiansToDegrees(CGFloat radians)
{
    return radians * 180/M_PI;
}


@implementation DrawArrow


+ (CGSize) size
{
    return CGSizeMake( 32.0, 32.0);
}


+ (UIImage *) drawArrowAtAngle:(CGFloat)degrees forSpeed:(CGFloat)speed
{
    return [self drawArrowAtAngle:degrees forSpeed:speed highlighted:NO];
}

+ (UIImage *) drawArrowAtAngle:(CGFloat)degrees forSpeed:(CGFloat)speed highlighted:(BOOL)highlighted
{
    return [self drawArrowAtAngle:degrees forSpeed:speed highlighted:highlighted color:[UIColor blackColor] hightlightedColor:[UIColor whiteColor]];
}

+ (UIImage *) drawArrowAtAngle:(CGFloat)degrees forSpeed:(CGFloat)speed highlighted:(BOOL)highlighted color:(UIColor *)color hightlightedColor:(UIColor *)highlightedColor;
{
    CGSize size = [self size];

    UIGraphicsBeginImageContextWithOptions( size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Rotate the image context
    CGContextTranslateCTM( context, (size.width/2), (size.height/2) );
    CGContextRotateCTM( context, DegreesToRadians(degrees));
    CGContextTranslateCTM( context, -1*(size.width/2), -1*(size.height/2) );

    // Add pole shadow
#if 0
    CGContextBeginPath(context);
    CGContextSetLineWidth( context, 2.0);
    CGContextSetAllowsAntialiasing( context, YES);
    CGContextSetGrayStrokeColor(context, 0.8, 0.8);
    CGContextMoveToPoint( context, 16.0, 7.0);
    CGContextAddLineToPoint( context, 16.0, 26.0);
    CGContextDrawPath(context, kCGPathStroke);

    // Add arrow head shadow
    CGContextBeginPath(context);
    CGContextSetLineWidth( context, 2.0);
    CGContextSetAllowsAntialiasing( context, YES);
    CGContextSetGrayFillColor(context, 0.8, 0.8);
    CGContextMoveToPoint( context, 16.0, 27.0);
    CGContextAddLineToPoint( context, 19.0, 21.0);
    CGContextAddLineToPoint( context, 13.0, 21.0);
    CGContextClosePath(context);
    CGContextFillPath(context);
#endif

    if ( highlighted ) {
        CGContextSetStrokeColorWithColor( context, [highlightedColor CGColor]);
        CGContextSetFillColorWithColor( context, [highlightedColor CGColor]);
    } else {
        CGContextSetStrokeColorWithColor( context, [color CGColor]);
        CGContextSetFillColorWithColor( context, [color CGColor]);
    }


    // Add pole
    CGContextSetLineWidth( context, 1.0);
    CGContextSetAllowsAntialiasing( context, YES);
    CGContextBeginPath(context);
    CGContextMoveToPoint( context, 16.0, 7.5);
    CGContextAddLineToPoint( context, 16.0, 26.0);
    CGContextDrawPath(context, kCGPathStroke);

    // Add arrow head
    CGContextBeginPath(context);
    //CGContextSetFillColorWithColor( context, [[UIColor blackColor] CGColor] );
    CGContextMoveToPoint( context, 16.0, 26.0);
    CGContextAddLineToPoint( context, 19.0, 21.0);
    CGContextAddLineToPoint( context, 13.0, 21.0);
    CGContextClosePath(context);
    CGContextFillPath(context);


    CGContextSetLineWidth( context, 1.0);
    CGContextSetAllowsAntialiasing( context, YES);

    double numIterations = speed/5;

    // Add wind speed markers
    for ( int i = 0; i < floor(numIterations); i++ ) {
        CGContextBeginPath(context);
        CGContextMoveToPoint( context, 10.0, 8.0+(i*2));
        CGContextAddLineToPoint( context, 16.0, 8.0+(i*2));
        CGContextDrawPath(context, kCGPathStroke);

    }

    // Add a half wind speed marker if it's between segments
    if ( speed > 5.0 && ((int)ceil(speed) % 5 != 0 || (speed-floor(speed)) > 0.0) ) {
        CGContextBeginPath(context);
        CGContextMoveToPoint( context, 13.0, 8.0+(floor(numIterations)*2));
        CGContextAddLineToPoint( context, 16.0, 8.0+(floor(numIterations)*2));
        CGContextDrawPath(context, kCGPathStroke);
    }

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;

}
@end
