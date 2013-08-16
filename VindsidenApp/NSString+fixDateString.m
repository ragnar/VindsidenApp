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
    //NSString *dateString = [self stringByReplacingCharactersInRange:NSMakeRange(19, 6) withString:([[NSTimeZone localTimeZone] isDaylightSavingTime] ? @"+0200" : @"+0100")];
    //NSString *dateString = [self stringByReplacingCharactersInRange:NSMakeRange(19, 6) withString:([[NSTimeZone localTimeZone] isDaylightSavingTime] ? @"+0000" : @"+0000")];
    //NSString *dateString = [self stringByAppendingString:@"+0000"];
    return self;
}


@end
