//
//  Datamanager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation
import CoreData


@objc public class Datamanager
{
    struct Config {
        static let sharedBundleIdentifier = "org.juniks.VindsidenKit"
        static let datamodelName = "Vindsiden"
        static let sqliteName = "Vindsiden.sqlite"
        static let sharedGroupName = "group.org.juniks.VindsidenApp"
        static let plotHistoryHours = 5.0
    }

    let _formatterQueue: dispatch_queue_t = dispatch_queue_create("formatter queue", nil)


    public class func sharedManager() -> Datamanager! {
        struct Static {
            static var instance: Datamanager? = nil
            static var onceToken: dispatch_once_t = 0
        }

        dispatch_once(&Static.onceToken) {
            Static.instance = self()
        }

        return Static.instance!
    }

    public required init() {

    }

    public func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

    public func cleanupPlots() {
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

            let result = childContext.executeFetchRequest(fetchRequest, error: &err) as Array<NSManagedObject>

            for object  in result {
                childContext.deleteObject(object)
            }

            childContext.save(&err)
            if let moc = self.managedObjectContext {
                moc.performBlock {
                    moc.save(&err)
                    return
                }
            }
        }
    }


    public lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()


    lazy var managedObjectModel: NSManagedObjectModel? = {
        let modelURL = NSBundle(identifier:Config.sharedBundleIdentifier).URLForResource(Config.datamodelName, withExtension: "momd")
        var _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)

        return _managedObjectModel
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let storeUrl = self.applicationDocumentsDirectory.URLByAppendingPathComponent(Config.sqliteName)
        var error: NSError? = nil
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel!)

        self.addSkipBackupAttributeToItemAtURL(storeUrl)

        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var failureReason = "There was an error creating or loading the application's saved data."
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }

        return coordinator
    }()

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
        if let actdate = _dateFormatter {
            return actdate
       }

       _dateFormatter = NSDateFormatter()
       _dateFormatter!.dateFormat = "yyyy-MM-dd' 'HH:mm:ssZZZ"
       _dateFormatter!.timeZone = NSTimeZone(name: "UTC")

       return _dateFormatter!
    }
    var _dateFormatter: NSDateFormatter? = nil

    public func dateFromString(string: String) -> NSDate!
    {
        var date: NSDate? = nil
        dispatch_sync(_formatterQueue) {
            date = self.dateFormatter.dateFromString(string)
        };

        return date!;
    }

    public lazy var sharedDefaults: NSUserDefaults? = {
        var _defaultManager = NSUserDefaults(suiteName: "group.org.juniks.VindsidenApp")
        return _defaultManager
    }()

}