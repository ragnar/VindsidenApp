//
//  CDStation.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 17.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "CDStation.h"
#import "CDPlot.h"
#import "NSSet+Sort.h"

#import "VindsidenKit/VindsidenKit-Swift.h"

#define kPlotHistoryHours 5


@implementation CDStation

@dynamic coordinateLat;
@dynamic coordinateLon;
@dynamic lastRefreshed;
@dynamic stationId;
@dynamic stationName;
@dynamic copyright;
@dynamic isHidden;
@dynamic lastMeasurement;
@dynamic order;
@dynamic stationText;
@dynamic statusMessage;
@dynamic yrURL;
@dynamic city;
@dynamic webCamText;
@dynamic webCamURL;
@dynamic webCamImage;
@dynamic plots;

#pragma mark -
#pragma mark MKAnnotation Delegate methods

- (CLLocationCoordinate2D) coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [self.coordinateLat doubleValue];
    coordinate.longitude = [self.coordinateLon doubleValue];
    return coordinate;
}

- (NSString *) title
{
    return self.stationName;
}

- (NSString *) subtitle
{
    return @"";
}


- (NSTimeInterval)fetchInterval
{
    NSArray *plots = [[self.plots filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"plotTime >= %@", [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours-1)*3600]]] sortedByKeyPath:@"plotTime" ascending:NO];

    NSTimeInterval waitInterval = 30;
    NSTimeInterval _refreshInterval = 0;

    if ( [plots count] >= 2 ) {
        CDPlot *plot = plots[0];
        CDPlot *plot2 = plots[1];
        _refreshInterval = [plot.plotTime timeIntervalSinceDate:plot2.plotTime];

        NSDate *nextRefresh  = [plot.plotTime dateByAddingTimeInterval:_refreshInterval];
        waitInterval = ([nextRefresh timeIntervalSinceDate:[NSDate date]] + 10 );
        if ( waitInterval <= 0 ) {
            waitInterval = 30;
        }
    }
    return waitInterval;
}


+ (void)updateStations:(NSArray *)stations
{
    NSManagedObjectContext *context = [[Datamanager sharedManager] managedObjectContext];
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = context;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    childContext.undoManager = nil;
    __block NSError *err = nil;

    [childContext performBlock:^{
        NSInteger order = [CDStation maxOrderForStationsInManagedObjectContext:childContext];
        BOOL newStations = NO;

        if ( order == 0 ) {
            order = 200;
        }

        for ( NSDictionary *station in stations ) {
            CDStation *managedObject = [CDStation newOrExistingStation:station[@"stationId"] inManagedObjectContext:childContext];

            for (id key in station ) {
                id v = station[key];
                if ( [v class] == [NSNull class] ) {
                    continue;
                }
                [managedObject setValue:v forKey:key];
            }

            if ( [managedObject isInserted] ) {
                newStations = YES;
                if ( [managedObject.stationId integerValue] == 1 ) {
                    managedObject.order = @101;
                    managedObject.isHidden = @NO;
                } else {
                    order++;
                    managedObject.order = @(order);
                    managedObject.isHidden = @YES;
                }
            }
        }

        if ( newStations ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:nil
                                            message:NSLocalizedString(@"ALERT_NEW_STATIONS_FOUND", @"New stations found. Go to settings to view them")
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }

        [childContext save:&err];
        [context performBlock:^{
            [context save:&err];
        }];
    }];
}


+ (CDStation *)existingStation:(NSNumber *)stationId inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    CDStation *existing = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CDStation"];
    request.predicate = [NSPredicate predicateWithFormat:@"stationId == %@", stationId];
    request.fetchLimit = 1;

    NSArray *array = [managedObjectContext executeFetchRequest:request error:nil];
    if ( [array count] ) {
        existing = array[0];
    }
    return existing;
}


+ (CDStation *)newOrExistingStation:(NSNumber *)stationId inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    CDStation *existing = [CDStation existingStation:stationId inManagedObjectContext:managedObjectContext];

    if ( nil == existing ) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDStation" inManagedObjectContext:managedObjectContext];
        existing = (CDStation *)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
    }

    return existing;
}


+ (CDStation *)searchForStation:(NSString *)search inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    CDStation *existing = nil;

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CDStation"];
    request.predicate = [NSPredicate predicateWithFormat:@"stationName contains[cd] %@", search];
    request.fetchLimit = 1;

    NSArray *array = [managedObjectContext executeFetchRequest:request error:nil];
    if ( [array count] ) {
        existing = array[0];
    }

    return existing;
}


+ (NSInteger)maxOrderForStationsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"CDStation" inManagedObjectContext:managedObjectContext];
    request.fetchLimit = 1;

    NSExpression *ex = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForKeyPath:@"order"]]];
    NSExpressionDescription *maxED = [[NSExpressionDescription alloc] init];
    [maxED setExpression:ex];
    [maxED setExpressionResultType:NSInteger16AttributeType];
    [maxED setName:@"nextNumber"];

    [request setPropertiesToFetch:@[maxED]];
    [request setResultType:NSDictionaryResultType];

    NSArray *maxes = [managedObjectContext executeFetchRequest:request error:nil];

    if ( maxes.count > 0 ) {
        return [maxes[0][@"nextNumber"] integerValue];
    }
    return 0;
    
}


+ (NSInteger)numberOfVisibleStations
{
    NSManagedObjectContext *context = [[Datamanager sharedManager] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"CDStation"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    fetchRequest.predicate = predicate;

    return [context countForFetchRequest:fetchRequest error:nil];
}


- (CDPlot *)lastRegisteredPlot
{
    NSDate *inDate = [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours-1)*3600];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *inputComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour) fromDate:inDate];
    NSDate *outDate = [gregorian dateFromComponents:inputComponents];
    NSArray *cdplots = [[self.plots filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"plotTime >= %@", outDate]] sortedByKeyPath:@"plotTime" ascending:NO];

    if ( [cdplots count] ) {
        return [cdplots firstObject];
    }

    return nil;
}


@end