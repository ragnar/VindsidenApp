//
//  CDPlot.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 17.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import <CoreData/CoreData.h>

@class CDStation;

@interface CDPlot : NSManagedObject
{
}

@property (nonatomic, retain) NSDate * plotTime;
@property (nonatomic, retain) NSNumber * windAvg;
@property (nonatomic, retain) NSNumber * windDir;
@property (nonatomic, retain) NSNumber * windMax;
@property (nonatomic, retain) NSNumber * windMin;
@property (nonatomic, retain) NSNumber * tempWater;
@property (nonatomic, retain) NSNumber * tempAir;
@property (nonatomic, retain) CDStation * station;

+ (CDPlot *) newOrExistingPlot:(NSDictionary *)dict forStation:(CDStation *)station inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)updatePlots:(NSArray *)plots completion:(void (^)(void))completion;

@end
