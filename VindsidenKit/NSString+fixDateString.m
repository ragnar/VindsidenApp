//
//  NSString+fixDateString.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16.08.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "NSString+fixDateString.h"

@implementation NSString (fixDateString)


- (NSString *)fixDateString
{
    NSString *ds = nil;

    if ( [self length] == 25 ) {
        ds = [self stringByReplacingCharactersInRange:NSMakeRange(19, 6) withString:@"+0000"];
    } else if ( [self rangeOfString:@"Z"].location != NSNotFound ) {
        ds = [self stringByReplacingCharactersInRange:NSMakeRange(19, 1) withString:@"+0000"];
    }
    return [ds stringByReplacingOccurrencesOfString:@"T" withString:@" "];
}


@end
