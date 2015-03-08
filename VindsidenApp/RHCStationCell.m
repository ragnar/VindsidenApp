//
//  RHCStationCell.m
//  Haugastol-v2
//
//  Created by Ragnar Henriksen on 25.04.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

@import VindsidenKit;

#import "RHCStationCell.h"
#import "NSSet+Sort.h"

#import "NSObject+performBlockCancel.h"
#import "RHEVindsidenAPIClient.h"
#import "RHEGraphView.h"


@interface RHCStationCell ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSTimer *updatedTimer;

@end


@implementation RHCStationCell

@synthesize currentStation = _currentStation;


- (void)awakeFromNib
{
    [super awakeFromNib];

    self.updatedAtLabel.text = @"";
    self.cameraButton.alpha = 0.0;
}


- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.updatedTimer invalidate];
    self.updatedTimer = nil;

    self.updatedAtLabel.text = NSLocalizedString(@"LABEL_UPDATING", @"Updating");

    self.cameraButton.alpha = 0.0;
    self.graphView.plots = nil;
    [self.stationView resetInfoLabels];
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


- (void)updateLastUpdatedLabel
{
    NSArray *cdplots = [[self.currentStation.plots filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"plotTime >= %@", [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours-1)*3600]]] sortedByKeyPath:@"plotTime" ascending:NO];

    if ( [cdplots count] ) {
        if ( [[cdplots[0] plotTime] compare:[NSDate date]] == NSOrderedAscending ) {
            self.updatedAtLabel.text = [[AppConfig sharedConfiguration] relativeDate:[cdplots[0] plotTime]];
        } else {
            self.updatedAtLabel.text = [[AppConfig sharedConfiguration] relativeDate:nil];
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
    NSManagedObjectContext *context = self.currentStation.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"CDPlot"];

    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"station == %@ AND plotTime >= %@", self.currentStation, outDate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"plotTime" ascending:NO]];

    NSArray *cdplots = [context executeFetchRequest:fetchRequest error:nil];

    if ( [cdplots count] ) {
        self.graphView.plots = cdplots;
        [self.stationView updateWithPlot:cdplots.firstObject];
        if ( [[cdplots[0] plotTime] compare:[NSDate date]] == NSOrderedAscending ) {
            self.updatedAtLabel.text = [[AppConfig sharedConfiguration] relativeDate:[cdplots.firstObject plotTime]];
        } else {
            self.updatedAtLabel.text = [[AppConfig sharedConfiguration] relativeDate:nil];
        }
    } else {
        self.updatedAtLabel.text = NSLocalizedString(@"LABEL_NOT_UPDATED", @"Not updated");
    }
}


#pragma mark -


- (void)setCurrentStation:(CDStation *)currentStation
{
    _currentStation = currentStation;

    [[AppConfig sharedConfiguration].applicationUserDefaults setInteger:[self.currentStation.stationId integerValue] forKey:@"selectedDefaultStation"];
    [[AppConfig sharedConfiguration].applicationUserDefaults synchronize];

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
}


- (CDStation *)currentStation
{
    [[[Datamanager sharedManager] managedObjectContext] processPendingChanges];
    NSTimeInterval oldStaleness = [[[Datamanager sharedManager] managedObjectContext] stalenessInterval];
    [[[Datamanager sharedManager] managedObjectContext] setStalenessInterval:0.0];
    [[[Datamanager sharedManager] managedObjectContext] refreshObject:_currentStation mergeChanges:NO];
    [[[Datamanager sharedManager] managedObjectContext] setStalenessInterval:oldStaleness];

    return _currentStation;
}


@end
