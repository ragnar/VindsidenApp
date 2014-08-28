//
//  RHCStationCell.m
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCStationCell.h"
#import <SORelativeDateTransformer/SORelativeDateTransformer.h>
#import "NSSet+Sort.h"

#import "NSObject+performBlockCancel.h"
#import "RHEVindsidenAPIClient.h"
#import "RHEGraphView.h"
#import "CDPlot.h"
#import "CDStation.h"

@import VindsidenKit;

@interface RHCStationCell ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) id autocompleteBlock;

@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;
@property (strong, nonatomic) NSTimer *updatedTimer;

@end

@implementation RHCStationCell


- (void)dealloc
{
    IGNORE_EXCEPTION( [[NSNotificationCenter defaultCenter] removeObserver:self name:NETWORK_STATUS_CHANGED object:nil] );
    DLOG(@"");
}


- (void)awakeFromNib
{
    [super awakeFromNib];

    self.dateTransformer = [[SORelativeDateTransformer alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityStatusChanged:) name:NETWORK_STATUS_CHANGED object:nil];

    self.updatedAtLabel.text = @"";
    self.cameraButton.alpha = 0.0;
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.stationView resetInfoLabels];

    [self.updatedTimer invalidate];
    self.updatedTimer = nil;

    self.updatedAtLabel.text = NSLocalizedString(@"LABEL_UPDATING", @"Updating");

    self.cameraButton.alpha = 0.0;
    self.graphView.plots = nil;

    [NSObject cancelBlock:self.autocompleteBlock];
    self.autocompleteBlock = nil;
}


- (NSDateFormatter *) dateFormatter
{
    if ( _dateFormatter ) {
        return _dateFormatter;
    }

    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

    return _dateFormatter;
}


- (void)networkReachabilityStatusChanged:(NSNotification *)notification
{
    DLOG(@"");
}


- (void)fetch
{
    [self fetchWithCompletionHandler:nil];
}


- (void)fetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ( nil == self.currentStation ) {
        DLOG(@"");
        return;
    }
    [[RHEVindsidenAPIClient defaultManager] fetchStationsPlotsForStation:self.currentStation.stationId
                                                              completion:^(BOOL success, NSArray *plots) {
                                                                  DLOG(@"");
                                                                  if ( success ) {
                                                                      [self updatePlots:plots];
                                                                      if ( completionHandler ) {
                                                                          completionHandler(UIBackgroundFetchResultNewData);
                                                                      }
                                                                  } else {
                                                                      if ( completionHandler ) {
                                                                          completionHandler(UIBackgroundFetchResultNoData);
                                                                      }
                                                                  }
                                                              } error:^(BOOL cancelled, NSError *error) {
                                                                  if ( NO == cancelled ) {
                                                                      [[RHCAlertManager defaultManager] showNetworkError:error];

                                                                      [self refresh];
                                                                  }
                                                              }
     ];
}


- (void)refresh
{
    if ( self.autocompleteBlock ) {
        [NSObject cancelBlock:self.autocompleteBlock];
        self.autocompleteBlock = nil;
    }

    self.autocompleteBlock = [NSObject performBlock:^{
        [self fetch];
        self.autocompleteBlock = nil;
    }
                                         afterDelay:[self.currentStation fetchInterval]];
}


- (void)updatePlots:(NSArray *)plots
{
    UIScrollView *scrollView = (UIScrollView *)self.superview;

    if ( [scrollView isDragging] ) {
        [NSObject performBlock:^{
            [self updatePlots:plots];
        }
                    afterDelay:0.2
         ];
        return;
    }

    [CDPlot updatePlots:plots completion:^{
        [self displayPlots];
        [NSObject cancelBlock:self.autocompleteBlock];
        self.autocompleteBlock = nil;
        [self refresh];
    }];
}


- (void)updateLastUpdatedLabel
{
    NSArray *cdplots = [[self.currentStation.plots filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"plotTime >= %@", [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours-1)*3600]]] sortedByKeyPath:@"plotTime" ascending:NO];

    if ( [cdplots count] ) {
        if ( [[cdplots[0] plotTime] compare:[NSDate date]] == NSOrderedAscending ) {
            self.updatedAtLabel.text = [self.dateTransformer transformedValue:[cdplots[0] plotTime]];
        } else {
            self.updatedAtLabel.text = [self.dateTransformer transformedValue:nil];
        }
    } else {
        self.updatedAtLabel.text = NSLocalizedString(@"LABEL_NOT_UPDATED", @"Not updated");
    }
}


- (void)displayPlots
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self syncDisplayPlots];
    });
}


- (void)syncDisplayPlots
{
    NSDate *inDate = [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours-1)*3600];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *inputComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour) fromDate:inDate];
    NSDate *outDate = [gregorian dateFromComponents:inputComponents];
    NSArray *cdplots = [[self.currentStation.plots filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"plotTime >= %@", outDate]] sortedByKeyPath:@"plotTime" ascending:NO];

    if ( [cdplots count] ) {
        self.graphView.plots = cdplots;
        [self.stationView updateWithPlot:cdplots[0]];
        if ( [[cdplots[0] plotTime] compare:[NSDate date]] == NSOrderedAscending ) {
            self.updatedAtLabel.text = [self.dateTransformer transformedValue:[cdplots[0] plotTime]];
        } else {
            self.updatedAtLabel.text = [self.dateTransformer transformedValue:nil];
        }
    } else {
        self.updatedAtLabel.text = NSLocalizedString(@"LABEL_NOT_UPDATED", @"Not updated");
    }
}


#pragma mark -


- (void)setCurrentStation:(CDStation *)currentStation
{
    _currentStation = currentStation;

    [[Datamanager sharedManager].sharedDefaults setInteger:[self.currentStation.stationId integerValue] forKey:@"selectedDefaultStation"];
    [[Datamanager sharedManager].sharedDefaults synchronize];

    self.stationNameLabel.text = self.currentStation.stationName;
    [self displayPlots];

    [self.updatedTimer invalidate];
    self.updatedTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                                 interval:1
                                                   target:self
                                                 selector:@selector(updateLastUpdatedLabel)
                                                 userInfo:nil
                                                  repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.updatedTimer forMode:NSDefaultRunLoopMode];

    [NSObject cancelBlock:self.autocompleteBlock];
    self.autocompleteBlock = nil;

    if ( NO == [self.currentStation isUpdated] ) {
        [self fetch];
    }
}


@end
