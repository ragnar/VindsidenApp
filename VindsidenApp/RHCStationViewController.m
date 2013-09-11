//
//  RHCStationViewController.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 28.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCStationViewController.h"
#import "RHEGraphView.h"
#import "RHCStationInfo.h"
#import <SORelativeDateTransformer/SORelativeDateTransformer.h>
#import "NSSet+Sort.h"
#import "RHEVindsidenAPIClient.h"

#import "CDStation.h"
#import "CDPlot.h"

@interface RHCStationViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *updatedAtLabel;
@property (weak, nonatomic) IBOutlet RHCStationInfo *stationView;
@property (weak, nonatomic) IBOutlet RHEGraphView *graphView;

@property (strong, nonatomic) SORelativeDateTransformer *dateTransformer;


- (IBAction)done:(id)sender;

@end


@implementation RHCStationViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dateTransformer = [[SORelativeDateTransformer alloc] init];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setCurrentStation:(CDStation *)currentStation
{
    _currentStation = currentStation;

    self.stationNameLabel.text = self.currentStation.stationName;
    [self displayPlots];

    if ( nil == self.currentStation ) {
        DLOG(@"");
        return;
    }

    [[RHEVindsidenAPIClient defaultManager] fetchStationsPlotsForStation:self.currentStation.stationId
                                                              completion:^(BOOL success, NSArray *stations) {
                                                                  if ( success ) {
                                                                      [self updatePlots:stations];
                                                                  }
                                                              } error:^(BOOL cancelled, NSError *error) {
                                                                  if ( NO == cancelled ) {
                                                                      [[RHCAlertManager defaultManager] showNetworkError:error];
                                                                  }
                                                              }
     ];
}


- (void)updatePlots:(NSArray *)plots
{
    [CDPlot updatePlots:plots completion:^{
        [self displayPlots];
    }];
}


- (void)displayPlots
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDate *inDate = [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours-1)*3600];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *inputComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit) fromDate:inDate];
        NSDate *outDate = [gregorian dateFromComponents:inputComponents];
        NSArray *cdplots = [[self.currentStation.plots filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"plotTime >= %@", outDate]] sortedByKeyPath:@"plotTime" ascending:NO];

        if ( [cdplots count] ) {
            self.graphView.plots = cdplots;
            [self.stationView updateWithPlot:cdplots[0]];
            self.updatedAtLabel.text = [self.dateTransformer transformedValue:[cdplots[0] plotTime]];
        } else {
            self.updatedAtLabel.text = NSLocalizedString(@"LABEL_NOT_UPDATED", @"Not updated");
        }
    });
}


#pragma mark - Actions


- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
