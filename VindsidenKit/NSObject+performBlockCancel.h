//
//  NSObject+performBlockCancel.h
//  haugastol
//
//  Created by Ragnar Henriksen on 03.09.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//
//  Source: https://gist.github.com/955123
//

#import <Foundation/Foundation.h>

@interface NSObject (performBlockCancel)


+ (id)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;
- (id)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

+ (void)cancelBlock:(id)block;

@end
