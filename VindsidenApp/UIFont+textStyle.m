//
//  UIFont+textStyle.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 01.07.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "UIFont+textStyle.h"
#import "UIFontDescriptor+textStyle.h"


@implementation UIFont (textStyle)


+ (UIFont *)tkd_preferredFontWithTextStyle:(NSString *)aTextStyle scale:(CGFloat)aScale
{
    UIFontDescriptor *newFontDescriptor = [UIFontDescriptor tkd_preferredFontDescriptorWithTextStyle:aTextStyle scale:aScale];

    return [UIFont fontWithDescriptor:newFontDescriptor size:newFontDescriptor.pointSize];
}

- (NSString *)tkd_textStyle
{
    return [self.fontDescriptor tkd_textStyle];
}

- (UIFont *)tkd_fontWithScale:(CGFloat)aScale
{
    return [self fontWithSize:lrint(self.pointSize * aScale)];
}

@end
