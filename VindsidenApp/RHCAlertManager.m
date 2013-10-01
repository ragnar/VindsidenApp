//
//  RHCAlertManager.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18.06.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <AFNetworking/AFURLConnectionOperation.h>
#import "RHCAlertManager.h"

@interface RHCAlertManager () <UIAlertViewDelegate>

@end


@implementation RHCAlertManager
{
    UIAlertView *_networkAlertView;
}


+ (id) defaultManager
{
    static RHCAlertManager *_defaultManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _defaultManager = [[RHCAlertManager alloc] init];
    });
    return _defaultManager;
}



- (id) init
{
    self = [super init];

    if ( nil != self ) {
    }

    return self;
}

- (void)showNetworkError:(NSError *)error
{
    if ( _networkAlertView ) {
        DLOG(@"");
        return;
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        NSString *message = error.userInfo[NSLocalizedDescriptionKey];

        if ( [error.domain isEqualToString:AFNetworkingErrorDomain]) {
            message = NSLocalizedString(@"NETWORK_ERROR_UNABLE_TO_LOAD", @"Unable to fetch data at this point.");
        }

        _networkAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [_networkAlertView show];
        
    });
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( alertView == _networkAlertView ) {
        _networkAlertView = nil;
    }
}

@end
