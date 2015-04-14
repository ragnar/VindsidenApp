//
//  CDPlot.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 17.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "CDPlot.h"
#import "CDStation.h"
#import "NSString+fixDateString.h"

#import <VindsidenKit/VindsidenKit-Swift.h>

@implementation CDPlot

@dynamic plotTime;
@dynamic windAvg;
@dynamic windDir;
@dynamic windMax;
@dynamic windMin;
@dynamic tempWater;
@dynamic tempAir;

@dynamic station;


+ (CDPlot *) newOrExistingPlot:(NSDictionary *)dict forStation:(CDStation *)station inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    CDPlot *existing = nil;
    NSString *dateString = [dict[@"plotTime"] fixDateString];
    NSDate *date = [[Datamanager sharedManager] dateFromString:dateString];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CDPlot"];

    request.predicate = [NSPredicate predicateWithFormat:@"station == %@ and plotTime == %@", station, date];
    request.fetchLimit = 1;

    NSArray *array = [managedObjectContext executeFetchRequest:request error:nil];

    if ( [array count] > 0 ) {
        existing = array[0];
    } else {
        existing = [[CDPlot alloc] initWithEntity:request.entity insertIntoManagedObjectContext:managedObjectContext];

        for (id key in dict ) {
            id v = dict[key];
            if ( [v class] == [NSNull class] ) {
                continue;
            } else if ( [key isEqualToString:@"plotTime"] ) {
                existing.plotTime = date;
                continue;
            } else if ( [key isEqualToString:@"windDir"]  ) {
                CGFloat value = [dict[key] floatValue];
                if ( value < 0 ) {
                    value = value + 360;
                }
                [existing setValue:@(value)
                            forKey:key];
                continue;
            } else if ( [key isEqualToString:@"stationID"] ) {
                continue;
            } else if ( [key isEqualToString:@"windMin"] ) {
                CGFloat value = [dict[key] floatValue];
                if ( value < 0 ) {
                    value = 0.0;
                }
                [existing setValue:@(value) forKey:key];
                continue;
            }
            [existing setValue:@([dict[key] floatValue]) forKey:key];
        }
    }

    return existing;
}


+ (void)updatePlots:(NSArray *)plots completion:(void (^)(void))completion
{
    if ( 0 == [plots count] ) {
        if ( completion ) {
            completion();
        }

        return;
    }

    NSManagedObjectContext *context = [[Datamanager sharedManager] managedObjectContext];
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = context;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    childContext.undoManager = nil;
    __block NSError *err = nil;

    [childContext performBlock:^{
        CDStation *thisStation = [CDStation existingStation:plots[0][@"stationID"] inManagedObjectContext:childContext];

        if ( thisStation == nil ) {
            [Logger DLOG:[NSString stringWithFormat:@"StationID %@ not found", plots[0][@"stationID"]] file:@"*" function:@(__PRETTY_FUNCTION__) line:__LINE__];

            if ( completion ) {
                completion();
            }

            return;
        }

        NSMutableSet *insertedPlots = [NSMutableSet set];

        for ( NSDictionary *dict in plots ) {
            CDPlot *managedObject = [CDPlot newOrExistingPlot:dict forStation:thisStation inManagedObjectContext:childContext];
            if ( [managedObject isInserted] ) {
                [insertedPlots addObject:managedObject];
            }
        }

        if ( insertedPlots.count ) {
            [thisStation willChangeValueForKey:@"plots"];
            [thisStation addPlots:insertedPlots];
            [thisStation didChangeValueForKey:@"plots"];
        }

        if ( [childContext hasChanges] && [childContext save:&err] == NO ) {
            [Logger DLOG:[NSString stringWithFormat:@"Save failed: %@", err.localizedDescription] file:@"*" function:@(__PRETTY_FUNCTION__) line:__LINE__];
            [Logger DLOG:[NSString stringWithFormat:@"Save failed: stationID: %@ - %@", plots[0][@"stationID"], thisStation] file:@"*" function:@(__PRETTY_FUNCTION__) line:__LINE__];
        }

        [childContext processPendingChanges];

        [context performBlock:^{
            if ( [context hasChanges] && [context save:&err] == NO ) {
                [Logger DLOG:[NSString stringWithFormat:@"Save failed: %@", err.localizedDescription] file:@"*" function:@(__PRETTY_FUNCTION__) line:__LINE__];
            }

            [context processPendingChanges];


            if ( completion ) {
                completion();
            }
        }];
    }];
}


@end
