//
//  RHCAppDelegate.m
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import <TestFlightSDK/TestFlight.h>
#import "RHCAppDelegate.h"
#import "RHCStationViewController.h"
#import "NSNumber+Convertion.h"
#import "NSString+isNumeric.h"
#import "RHCViewController.h"

#import "CDPlot.h"
#import "CDStation.h"

@interface RHCAppDelegate ()

@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@end


@implementation RHCAppDelegate
{
    dispatch_queue_t _formatterQueue;
}


@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize dateFormatter = _dateFormatter;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIToolbar appearance] setTintColor:RGBCOLOR( 227.0, 60.0, 13.0)];
    [[UINavigationBar appearance] setTintColor:RGBCOLOR( 227.0, 60.0, 13.0)];

    _formatterQueue = dispatch_queue_create("formatter queue", NULL);
    
////#ifndef DEBUG
//    [TestFlight setOptions:@{@"disableInAppUpdates":@NO}];
//    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
//
////#endif
//    [TestFlight takeOff:@"b97e9c55-3aae-4f18-bc27-6fac0e973438"];

    // Override point for customization after application launch.
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUnit"] == 0 ) {
        [[NSUserDefaults standardUserDefaults] setInteger:SpeedConvertionToMetersPerSecond forKey:@"selectedUnit"];
        [[NSUserDefaults standardUserDefaults] synchronize];

    }

    [self cleanupPlots];

    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
    if ( url.host == nil || [url.host rangeOfString:@"station" options:NSCaseInsensitiveSearch].location == NSNotFound ) {
        return NO;
    }
    return YES;
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ( url.host == nil || [url.host rangeOfString:@"station" options:NSCaseInsensitiveSearch].location == NSNotFound ) {
        return NO;
    }

    id ident = [url.pathComponents lastObject];
    CDStation *station = nil;
    if ( [ident isNumeric] ) {
        station = [CDStation existingStation:ident inManagedObjectContext:[self managedObjectContext]];
    } else {
        station = [CDStation searchForStation:ident inManagedObjectContext:[self managedObjectContext]];
    }

    if ( nil == station ) {
        return NO;
    }

    if ( self.window.rootViewController.presentedViewController ) {
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
            [self openStationViewController:station];
        }];
    } else {
        [self openStationViewController:station];
    }

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    NSError *error = nil;
    if ( _managedObjectContext ) {
        if ( [_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


#if 0
- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
    DLOG(@"");
}


- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
    DLOG(@"");
}
#endif


- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DLOG(@"fetch");
    UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
    RHCViewController *vc = (RHCViewController *)[nc.viewControllers firstObject];

    [vc updateContentWithCompletionHandler:completionHandler];
}



#pragma mark - CoreData Stack


- (NSManagedObjectContext *)managedObjectContext
{
    if ( _managedObjectContext ) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel
{
    if ( _managedObjectModel ) {
        return _managedObjectModel;
    }

    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if ( _persistentStoreCoordinator ) {
        return _persistentStoreCoordinator;
    }

    NSURL *storeUrl = [NSURL fileURLWithPath:[[self applicationPrivateDocumentsDirectory] stringByAppendingPathComponent:@"Vindsiden.sqlite"]];

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    

    NSDictionary *fileAttributes = @{ NSFileProtectionKey : NSFileProtectionComplete };

    if ( ! [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:[storeUrl path] error:&error] ) {
        DLOG(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory


- (NSString *) applicationPrivateDocumentsDirectory
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Private Documents"];

    [fm createDirectoryAtPath:path withIntermediateDirectories:YES
                   attributes:nil
                        error:nil];

    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    return path;
}


- (void) cleanupPlots
{
    NSManagedObjectContext *context = [(id)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = context;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    childContext.undoManager = nil;
    __block NSError *err = nil;

    [childContext performBlock:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDPlot" inManagedObjectContext:childContext];
        [fetchRequest setEntity:entity];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"plotTime < %@", [[NSDate date] dateByAddingTimeInterval:-1*(kPlotHistoryHours*3600)]];
        [fetchRequest setPredicate:predicate];

        NSArray *result = [childContext executeFetchRequest:fetchRequest error:nil];

        for ( CDPlot *object in result ) {
            [childContext deleteObject:object];
        }
        [childContext save:&err];
        [context performBlock:^{
            [context save:&err];
        }];
        
    }];
}


#pragma mark - 


- (void)openStationViewController:(CDStation *)station
{
    UINavigationController *navCon = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"modalStationView"];
    RHCStationViewController *controller = navCon.viewControllers[0];

    [self.window.rootViewController presentViewController:navCon
                                                 animated:YES
                                               completion:^{
                                                   controller.currentStation = station;
                                               }
     ];
}


- (NSDateFormatter *)dateFormatter
{
    if ( nil != _dateFormatter ) {
        return _dateFormatter;
    }

    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ssZZZ"];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];

    return _dateFormatter;
}


- (NSDate *)dateFromString:(NSString *)string
{
    NSDate __block *date = nil;
    dispatch_sync(_formatterQueue, ^{
        date = [[self dateFormatter] dateFromString:string];
    });

    return date;
}


@end
