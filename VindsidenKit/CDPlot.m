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
#import "NSNumber+Between.h"

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


- (NSString *)windDirectionString
{
    CGFloat direction = [self.windDir floatValue];

    if ( direction > 360.0 || direction < 0 ) {
        direction = 0.0;
    }
    NSNumber *dir = @(direction);


    if ( [dir isBetween:0.0 and:11.25] || [dir isBetween:348.75 and:360.001]) {
        return NSLocalizedString(@"DIRECTION_N", @"N");
    } else if ( [dir isBetween:11.25 and:33.35] ) {
        return NSLocalizedString(@"DIRECTION_NNE", @"NNE");
    } else if ( [dir isBetween:33.75 and:56.25] ) {
        return NSLocalizedString(@"DIRECTION_NE", @"NE");
    } else if ( [dir isBetween:56.25 and:78.75] ) {
        return NSLocalizedString(@"DIRECTION_ENE", @"ENE");
    } else if ( [dir isBetween:78.75 and:101.25] ) {
        return NSLocalizedString(@"DIRECTION_E", @"E");
    } else if ( [dir isBetween:101.25 and:123.75] ) {
        return NSLocalizedString(@"DIRECTION_ESE", @"ESE");
    } else if ( [dir isBetween:123.75 and:146.25] ) {
        return NSLocalizedString(@"DIRECTION_SE", @"SE");
    } else if ( [dir isBetween:146.25 and:168.75] ) {
        return NSLocalizedString(@"DIRECTION_SSE", @"SSE");
    } else if ( [dir isBetween:168.75 and:191.25] ) {
        return NSLocalizedString(@"DIRECTION_S", @"S");
    } else if ( [dir isBetween:191.25 and:213.75] ) {
        return NSLocalizedString(@"DIRECTION_SSW", @"SSW");
    } else if ( [dir isBetween:213.75 and:236.25] ) {
        return NSLocalizedString(@"DIRECTION_SW", @"SW");
    } else if ( [dir isBetween:236.25 and:258.75] ) {
        return NSLocalizedString(@"DIRECTION_WSW", @"WSW");
    } else if ( [dir isBetween:258.75 and:281.25] ) {
        return NSLocalizedString(@"DIRECTION_W", @"W");
    } else if ( [dir isBetween:281.25 and:303.75] ) {
        return NSLocalizedString(@"DIRECTION_WNW", @"WNW");
    } else if ( [dir isBetween:303.75 and:326.25] ) {
        return NSLocalizedString(@"DIRECTION_NW", @"NW");
    } else if ( [dir isBetween:326.25 and:348.75] ) {
        return NSLocalizedString(@"DIRECTION_NNW", @"NNW");
    } else {
        return NSLocalizedString(@"DIRECTION_UKN", @"UKN");
    }
}


@end
