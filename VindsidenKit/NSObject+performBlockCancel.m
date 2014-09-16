//
//  NSObject+performBlockCancel.m
//  haugastol
//
//  Created by Ragnar Henriksen on 03.09.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import "NSObject+performBlockCancel.h"

@implementation NSObject (performBlockCancel)


+ (id)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    if ( !block ) {
         return nil;
    }

    __block BOOL cancelled = NO;

    void (^wrappingBlock)(BOOL) = ^(BOOL cancel) {
        if (cancel) {
            cancelled = YES;
            return;
        }

        if ( !cancelled ) {
            block();
        }
    };

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        wrappingBlock(NO);
    });

    return wrappingBlock;
}


- (id)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    if ( !block ) {
        return nil;
    }

    __block BOOL cancelled = NO;

    void (^wrappingBlock)(BOOL) = ^(BOOL cancel) {
        if (cancel) {
            cancelled = YES;
            return;
        }

        if ( !cancelled ) {
            block();
        }
    };

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        wrappingBlock(NO);
    });

    return wrappingBlock;
}


+ (void) cancelBlock:(id)block
{
    if ( !block ) {
        return;
    }

    void (^aWrappingBlock)(BOOL) = (void(^)(BOOL))block;
    aWrappingBlock(YES);
}


@end
