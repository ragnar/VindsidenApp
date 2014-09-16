//
//  NSNumber+Between.m
//  haugastol
//
//  Created by Ragnar Henriksen on 27.03.11.
//  Copyright 2011 Shortcut AS. All rights reserved.
//

#import "NSNumber+Between.h"

@implementation NSNumber (Between)

- (BOOL) isBetween:(CGFloat)from and:(CGFloat)to
{
    return ([self floatValue] >= from && [self floatValue] < to);
}

@end
