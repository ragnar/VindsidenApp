//
//  NSSet+Sort.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 02.10.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

@import Foundation;

@interface NSSet (Sort)

- (NSArray *) sortedByKeyPath:(NSString *)keyPath ascending:(BOOL)ascending;
- (NSArray *) sortedSetUsingSortDescriptors:(NSArray *)sortDescriptors;

@end
