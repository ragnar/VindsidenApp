//
//  DrawArrow.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 18.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

@import UIKit;


@interface DrawArrow : UIImage
{
}

+ (CGSize) size;
+ (UIImage *) drawArrowAtAngle:(CGFloat)degrees forSpeed:(CGFloat)speed;
+ (UIImage *) drawArrowAtAngle:(CGFloat)degrees forSpeed:(CGFloat)speed highlighted:(BOOL)highlighted;
+ (UIImage *) drawArrowAtAngle:(CGFloat)degrees forSpeed:(CGFloat)speed highlighted:(BOOL)highlighted color:(UIColor *)color hightlightedColor:(UIColor *)highlightedColor;

@end
