//
//  RHCAlertManager.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18.06.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <AFNetworking/AFURLConnectionOperation.h>
#import "RHCAlertManager.h"
#import "RHCAppDelegate.h"



@implementation RHCAlertManager
{
    BOOL _showingError;
    UIAlertController *_networkAlertController;
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
    if ( _showingError ) {
        DLOG(@"");
        return;
    }

    _showingError = YES;

    dispatch_async(dispatch_get_main_queue(), ^{

        NSString *message = error.userInfo[NSLocalizedDescriptionKey];

        if ( [error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] || [error.domain isEqualToString:NSURLErrorDomain]) {
            message = NSLocalizedString(@"NETWORK_ERROR_UNABLE_TO_LOAD", @"Unable to fetch data at this point.");
        }

        _networkAlertController = [UIAlertController alertControllerWithTitle:@""
                                                                      message:message
                                                               preferredStyle:UIAlertControllerStyleAlert];

        UIAlertController* __weak weakAlert = _networkAlertController;
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                                  _showingError = NO;
                                                              }];
        [_networkAlertController addAction:defaultAction];

        RHCAppDelegate *delegate = (RHCAppDelegate *)[UIApplication sharedApplication].delegate;

        UIViewController *controller = delegate.window.rootViewController;
        [controller presentViewController:_networkAlertController animated:YES completion:nil];
    });
}

@end
