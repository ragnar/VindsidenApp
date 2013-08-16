//
//  CDPlot.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 17.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import "CDPlot.h"
#import "CDStation.h"
#import "RHCAppDelegate.h"
#import "NSString+fixDateString.h"

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
    RHCAppDelegate *_appDelegate = [[UIApplication sharedApplication] delegate];
    NSString *dateString = [[dict objectForKey:@"plotTime"] fixDateString];
    NSDate *date = [_appDelegate dateFromString:dateString];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CDPlot"];

    request.predicate = [NSPredicate predicateWithFormat:@"station == %@ and plotTime == %@", station, date];
    request.fetchLimit = 1;

    NSArray *array = [managedObjectContext executeFetchRequest:request error:nil];

    if ( [array count] > 0 ) {
        existing = [array objectAtIndex:0];
    } else {
        existing = [[CDPlot alloc] initWithEntity:request.entity insertIntoManagedObjectContext:managedObjectContext];

        for (id key in dict ) {
            id v = [dict objectForKey:key];
            if ( [v class] == [NSNull class] ) {
                continue;
            } else if ( [key isEqualToString:@"plotTime"] ) {
                existing.plotTime = date;
                continue;
            } else if ( [key isEqualToString:@"windDir"]  ) {
                CGFloat value = [[dict objectForKey:key] floatValue];
                if ( value < 0 ) {
                    value = value + 360;
                }
                [existing setValue:[NSNumber numberWithFloat:value]
                            forKey:key];
                continue;
            }
            [existing setValue:[NSNumber numberWithFloat:[[dict objectForKey:key] floatValue]] forKey:key];
        }
    }

    return existing;
}


+ (void)updatePlots:(NSArray *)plots forStation:(CDStation *)station completion:(void (^)(void))completion
{
    NSManagedObjectContext *context = [(id)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = context;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    childContext.undoManager = nil;
    __block NSError *err = nil;

    [childContext performBlock:^{
        CDStation *thisStation = (CDStation *)[childContext objectWithID:[station objectID]];
        for ( NSDictionary *dict in plots ) {
            CDPlot *managedObject = [CDPlot newOrExistingPlot:dict forStation:station inManagedObjectContext:childContext];
            if ( [managedObject isInserted] ) {
                managedObject.station = thisStation;
            }
        }

        [childContext save:&err];
        [context performBlockAndWait:^{
            [context save:&err];
            if ( completion ) {
                completion();
            }
        }];
    }];
}


@end
