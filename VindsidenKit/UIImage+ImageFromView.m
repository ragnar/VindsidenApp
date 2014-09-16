//
//  UIImage+ImageFromView.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 01.10.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "UIImage+ImageFromView.h"


@implementation UIImage (ImageFromView)

+ (UIImage *)imageFromView:(UIView *)view
{
    CGRect rect = [view bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);

    [view drawViewHierarchyInRect:rect afterScreenUpdates:NO];

    [[UIColor lightGrayColor] setFill];
    [[UIColor lightGrayColor] setStroke];
    UIRectFrameUsingBlendMode( rect, kCGBlendModeNormal);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

@end
