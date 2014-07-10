//
//  UIFont+textStyle.h
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 01.07.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

@import UIKit;

@interface UIFont (textStyle)

+ (UIFont *)tkd_preferredFontWithTextStyle:(NSString *)aTextStyle scale:(CGFloat)aScale;

- (NSString *)tkd_textStyle;
- (UIFont *)tkd_fontWithScale:(CGFloat)fontScale;

@end
