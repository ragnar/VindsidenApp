//
//  CDStation.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 17.09.10.
//  Copyright (c) 2010 Shortcut AS. All rights reserved.
//

#import <CoreData/CoreData.h>
@import MapKit;

@class CDPlot;

@interface CDStation : NSManagedObject <MKAnnotation>
{
}

@property (nonatomic, retain) NSNumber * coordinateLat;
@property (nonatomic, retain) NSNumber * coordinateLon;
@property (nonatomic, retain) NSDate * lastRefreshed;
@property (nonatomic, retain) NSNumber * stationId;
@property (nonatomic, retain) NSString * stationName;
@property (nonatomic, retain) NSString * yrURL;
@property (nonatomic, retain) NSString * copyright;
@property (nonatomic, retain) NSNumber * isHidden;
@property (nonatomic, retain) NSDate * lastMeasurement;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * stationText;
@property (nonatomic, retain) NSString * statusMessage;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * webCamText;
@property (nonatomic, retain) NSString * webCamURL;
@property (nonatomic, retain) NSString * webCamImage;
@property (nonatomic, retain) NSSet *plots;

- (NSTimeInterval)fetchInterval;
+ (void)updateStations:(NSArray *)stations completion:(void (^)(BOOL newStations))completion;
+ (CDStation *)existingStation:(NSNumber *)stationId inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (CDStation *)newOrExistingStation:(NSNumber *)stationId inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (CDStation *)searchForStation:(NSString *)search inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSInteger)maxOrderForStationsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSInteger)numberOfVisibleStations;

- (CDPlot *)lastRegisteredPlot;

@end

@interface CDStation (CoreDataGeneratedAccessors)

- (void) addPlotsObject:(CDPlot *)value;
- (void) removePlotsObject:(CDPlot *)value;
- (void) addPlots:(NSSet *)value;
- (void) removePlots:(NSSet *)value;

@end


@interface CDStation (MKAnnotationAccessors)
- (CLLocationCoordinate2D) coordinate;
@end
