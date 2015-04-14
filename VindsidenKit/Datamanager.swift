//
//  Datamanager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation
import CoreData


@objc(Datamanager)
public class Datamanager
{

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("mainManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: managedObjectContext)
    }


    func mainManagedObjectContextDidSave(notification: NSNotification) -> Void {
        DLOG("Saving MOC based on notification")
        managedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
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

    public func cleanupPlots(completionHandler: ((Void) -> Void)? = nil) -> Void {
        let childContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        childContext.parentContext = managedObjectContext
        childContext.mergePolicy = NSRollbackMergePolicy;
        childContext.undoManager = nil
        var err: NSError?

        childContext.performBlock {
            let fetchRequest = NSFetchRequest(entityName: "CDPlot")
            let interval: NSTimeInterval = -1.0*((1.0+AppConfig.Global.plotHistory)*3600.0)
            let time = NSDate(timeIntervalSinceNow: interval)
            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time)

            let result = childContext.executeFetchRequest(fetchRequest, error: &err) as! [NSManagedObject]

            for object  in result {
                childContext.deleteObject(object)
            }

            if childContext.save(&err) == false {
                DLOG("Save failed: \(err)")
            }

            childContext.processPendingChanges()

            if let moc = self.managedObjectContext {
                moc.performBlock {
                    if moc.save(&err) == false {
                        DLOG("Save failed: \(err)")
                    }
                    moc.processPendingChanges()
                    completionHandler?()
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
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()


    lazy var managedObjectModel: NSManagedObjectModel? = {
        let modelURL = NSBundle(identifier: AppConfig.Bundle.frameworkBundleIdentifier)?.URLForResource(AppConfig.CoreData.datamodelName, withExtension: "momd")
        var _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)

        return _managedObjectModel
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {

        let storeUrl = self.applicationDocumentsDirectory.URLByAppendingPathComponent(AppConfig.CoreData.sqliteName)
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
            error = NSError(domain: "org.juniks.VindsidenApp", code: 9999, userInfo: dict as [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }

        return coordinator
    }()

    var applicationDocumentsDirectory: NSURL {
        let url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(AppConfig.ApplicationGroups.primary)
        if let actualurl = url {
            return actualurl as NSURL
        } else {
            return NSURL()
        }
    }

    func addSkipBackupAttributeToItemAtURL( url: NSURL) -> Void
    {
        if let path = url.path {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                var error: NSError?
                let success = url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey, error: &error)

                if success == false {
                    NSLog("Error excluding \(url.lastPathComponent) from backup \(error)");
                }
            }
        }
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
}