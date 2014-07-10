//
//  UIFontDescriptor+textStyle.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 01.07.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "UIFontDescriptor+textStyle.h"

@implementation UIFontDescriptor (textStyle)


+ (UIFontDescriptor *)tkd_preferredFontDescriptorWithTextStyle:(NSString *)aTextStyle scale:(CGFloat)aScale
{
    UIFontDescriptor *newBaseDescriptor = [self preferredFontDescriptorWithTextStyle:aTextStyle];
    return [newBaseDescriptor fontDescriptorWithSize:lrint([newBaseDescriptor pointSize] * aScale)];
}


- (NSString *)tkd_textStyle
{
    return [self objectForKey:@"NSCTFontUIUsageAttribute"];
}


- (UIFontDescriptor *)tkd_fontDescriptorWithScale:(CGFloat)aScale
{
    return [self fontDescriptorWithSize:lrint(self.pointSize * aScale)];
}

@end
