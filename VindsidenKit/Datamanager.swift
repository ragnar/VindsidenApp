//
//  Datamanager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation
import CoreData


@objc class Datamanager
{
    struct Config {
        static let sharedBundleIdentifier = "org.juniks.VindsidenKit"
        static let datamodelName = "Vindsiden"
        static let sqliteName = "Vindsiden.sqlite"
        static let sharedGroupName = "group.org.juniks.VindsidenApp"
        static let plotHistoryHours = 5.0
    }

    let _formatterQueue: dispatch_queue_t = dispatch_queue_create("formatter queue", nil)


    class func sharedManager() -> Datamanager! {
        struct Static {
            static var instance: Datamanager? = nil
            static var onceToken: dispatch_once_t = 0
        }

        dispatch_once(&Static.onceToken) {
            Static.instance = self()
        }

        return Static.instance!
    }

    @required init() {

    }

    func saveContext () {
        var error: NSError? = nil
        let managedObjectContext = self.managedObjectContext
        if managedObjectContext != nil {
            if managedObjectContext.hasChanges && !managedObjectContext.save(&error) {
                abort()
            }
        }
    }

    func cleanupPlots() {
//        NSManagedObjectContext *context = [(id)[[UIApplication sharedApplication] delegate] managedObjectContext];
//        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        childContext.parentContext = context;
//        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
//        childContext.undoManager = nil;
//        __block NSError *err = nil;
//
//        [childContext performBlock:^{
//            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//            NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDPlot" inManagedObjectContext:childContext];
//            [fetchRequest setEntity:entity];
//
//            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"plotTime < %@", [[NSDate date] dateByAddingTimeInterval:-1*((1+kPlotHistoryHours)*3600)]];
//            [fetchRequest setPredicate:predicate];
//
//            NSArray *result = [childContext executeFetchRequest:fetchRequest error:nil];
//
//            for ( CDPlot *object in result ) {
//            [childContext deleteObject:object];
//            }
//            [childContext save:&err];
//            [context performBlock:^{
//            [context save:&err];
//            }];
//            
//            }];

        let childContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        childContext.parentContext = managedObjectContext
        //childContext.mergePolicy =
        childContext.undoManager = nil
        var err: NSError?

        childContext.performBlock {
            let fetchRequest = NSFetchRequest(entityName: "CDPlot")
            let interval: NSTimeInterval = -1.0*((1.0+Config.plotHistoryHours)*3600.0)
            let time = NSDate(timeIntervalSinceNow: interval)
            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time)

            let result = childContext.executeFetchRequest(fetchRequest, error: &err) as Array<CDPlot>

            for object  in result {
                childContext.deleteObject(object)
            }

            childContext.save(&err)
            self.managedObjectContext.performBlock {
                self.managedObjectContext.save(&err)
                return
            }
        }
    }


    var managedObjectContext: NSManagedObjectContext {
    if !_managedObjectContext {
        let coordinator = self.persistentStoreCoordinator
        if coordinator != nil {
            _managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
            _managedObjectContext!.persistentStoreCoordinator = coordinator
        }
        }
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil

    var managedObjectModel: NSManagedObjectModel {
    if !_managedObjectModel {
        let modelURL = NSBundle(identifier:Config.sharedBundleIdentifier).URLForResource(Config.datamodelName, withExtension: "momd")
        _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
        }
        return _managedObjectModel!
    }
    var _managedObjectModel: NSManagedObjectModel? = nil

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
    if !_persistentStoreCoordinator {
        let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent(Config.sqliteName)
        var error: NSError? = nil

        addSkipBackupAttributeToItemAtURL(storeURL)

        _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if _persistentStoreCoordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error) == nil {
            abort()
        }
        }
        return _persistentStoreCoordinator!
    }
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil

    var applicationDocumentsDirectory: NSURL {
    let url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(Config.sharedGroupName)
        if let actualurl = url {
            return actualurl as NSURL
        } else {
            return NSURL()
        }
    }

    func addSkipBackupAttributeToItemAtURL( url: NSURL) -> Void {
//        assert(NSFileManager.defaultManager().fileExistsAtPath(url.path), "File must exist", file: __FILE__, line: __LINE__)
//
//        var error: NSError? = nil
//        let success = url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey, error:&error)
//        if success == false {
//            NSLog("Error excluding \(url.lastPathComponent) from backup \(error)");
//        }
    }

    var dateFormatter: NSDateFormatter {
    if !_dateFormatter {
        _dateFormatter = NSDateFormatter()
        _dateFormatter!.dateFormat = "yyyy-MM-dd' 'HH:mm:ssZZZ"
        _dateFormatter!.timeZone = NSTimeZone(name: "UTC")
        }
        return _dateFormatter!
    }
    var _dateFormatter: NSDateFormatter? = nil

    func dateFromString(string: String) -> NSDate!
    {
        var date: NSDate? = nil
        dispatch_sync(_formatterQueue) {
            date = self.dateFormatter.dateFromString(string)
        };

        return date!;
    }

    /*
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
    
*/
}