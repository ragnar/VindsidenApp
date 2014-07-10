//
//  NSString+isNumeric.m
//
//  Created by Ragnar Henriksen on 05.10.09.
//  Copyright 2009 Shortcut AS. All rights reserved.
//

#import "NSString+isNumeric.h"

@implementation NSString (isNumeric)

- (BOOL)isNumeric
{
    NSScanner *sc = [NSScanner scannerWithString:self];
    if ( [sc scanFloat:NULL] ) {
        return [sc isAtEnd];
    }
    return NO;
}

@end
