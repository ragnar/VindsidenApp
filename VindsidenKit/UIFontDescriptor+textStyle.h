//
//  UIFontDescriptor+textStyle.h
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 01.07.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFontDescriptor (textStyle)

+ (UIFontDescriptor *)tkd_preferredFontDescriptorWithTextStyle:(NSString *)aTextStyle scale:(CGFloat)aScale;

- (NSString *)tkd_textStyle;
- (UIFontDescriptor *)tkd_fontDescriptorWithScale:(CGFloat)aScale;

@end
