//
//  NSNumber+Between.h
//  haugastol
//
//  Created by Ragnar Henriksen on 27.03.11.
//  Copyright 2011 Shortcut AS. All rights reserved.
//

@import Foundation;
@import CoreGraphics;


@interface NSNumber (Between)
- (BOOL) isBetween:(CGFloat)from and:(CGFloat)to;
@end
