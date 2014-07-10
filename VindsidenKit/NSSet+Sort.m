//
//  NSSet+Sort.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 02.10.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "NSSet+Sort.h"


@implementation NSSet (Sort)

- (NSArray *) sortedByKeyPath:(NSString *)keyPath ascending:(BOOL)ascending
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:keyPath ascending:ascending];
    NSArray *sortDescriptors = @[sortDescriptor];
    NSArray *sorted = [NSArray arrayWithArray:[self sortedSetUsingSortDescriptors:sortDescriptors]];

    return sorted;
}

- (NSArray *) sortedSetUsingSortDescriptors:(NSArray *)sortDescriptors
{
    NSMutableArray *toBeSorted = [NSMutableArray arrayWithArray:[self allObjects]];
    [toBeSorted sortUsingDescriptors:sortDescriptors];
    return toBeSorted;
}


@end
