//
//  Datamanager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation
import CoreData

#if os(iOS)
import MobileCoreServices
import CoreSpotlight
#endif


@objc(Datamanager)
public class Datamanager : NSObject
{
    let _formatterQueue: dispatch_queue_t = dispatch_queue_create("formatter queue", nil)


    public class func sharedManager() -> Datamanager! {
        struct Static {
            static var instance: Datamanager? = nil
            static var onceToken: dispatch_once_t = 0
        }

        dispatch_once(&Static.onceToken) {
            Static.instance = self.init()
        }

        return Static.instance!
    }


    public required override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("mainManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: managedObjectContext)
    }


    func mainManagedObjectContextDidSave(notification: NSNotification) -> Void {
        DLOG("Saving MOC based on notification")
        managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
    }


    public func saveContext () {
        if self.managedObjectContext.hasChanges {
            do {
                try self.managedObjectContext.save()
            } catch let error as NSError {
                NSLog("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }


    public func cleanupPlots(completionHandler: ((Void) -> Void)? = nil) -> Void {

        let childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        childContext.parentContext = managedObjectContext
        childContext.mergePolicy = NSRollbackMergePolicy;
        childContext.undoManager = nil

        childContext.performBlock { () -> Void in
            let fetchRequest = NSFetchRequest(entityName: "CDPlot")
            let interval: NSTimeInterval = -1.0*((1.0+AppConfig.Global.plotHistory)*3600.0)
            let time = NSDate(timeIntervalSinceNow: interval)
            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time)

            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            request.resultType = .ResultTypeCount
            do {
                let result = try childContext.executeRequest(request) as! NSBatchDeleteResult
                DLOG("Deleted \(result.result!) plots")

                try childContext.save()

                childContext.processPendingChanges()

                self.managedObjectContext.performBlock {
                    do {
                        try self.managedObjectContext.save()
                        self.managedObjectContext.processPendingChanges()
                        completionHandler?()
                    } catch {
                        DLOG("Save failed: \(error)")
                        completionHandler?()
                    }
                }
            } catch {
                DLOG("Save failed: \(error)")
                completionHandler?()
            }
        }
    }


    public func removeStaleStationsIds( stations: [Int], inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Void {
        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.predicate = NSPredicate(format: "NOT stationId IN (%@)", stations)

        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        request.resultType = .ResultTypeCount

        do {
            let result = try managedObjectContext.executeRequest(request) as! NSBatchDeleteResult
            DLOG("Deleted \(result.result!) station(s)")
        } catch {
            DLOG("Delete failed: \(error)")
        }
    }


    #if os(iOS)
    public func indexActiveStations() -> Void {
        DLOG("Trying new indexing method")
        return

        let stations = CDStation.visibleStationsInManagedObjectContext(Datamanager.sharedManager().managedObjectContext)
        var items = [CSSearchableItem]()

        for station in stations {
            let search = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
            search.city = station.city
            search.latitude = station.coordinateLat
            search.longitude = station.coordinateLon
            search.namedLocation = station.city
            search.displayName = station.stationName
            search.copyright = station.copyright
            search.keywords = ["kite", "surf", "wind", "fluid", "naish", "ozone", "f-one"]
            search.title = station.stationName
            search.contentDescription = station.city

            let url = "vindsiden://station/\(station.stationId!)"
            let item = CSSearchableItem(uniqueIdentifier: url, domainIdentifier: AppConfig.Bundle.appName, attributeSet: search)
            items.append(item)
        }

        let index = CSSearchableIndex()
        index.beginIndexBatch()

        index.deleteAllSearchableItemsWithCompletionHandler { (error: NSError?) -> Void in
            DLOG("Removed all indexed entries: \(error?.localizedDescription)")

            if items.count > 0 {
                CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(items, completionHandler: { (error: NSError?) -> Void in
                    DLOG("Index completed: \(error?.localizedDescription)")
                })
            }
        }

        index.endIndexBatchWithClientState(NSData()) { (error: NSError?) -> Void in
            DLOG("Index completed: \(error?.localizedDescription)")
        }
    }

    public func addStationToIndex( station: CDStation ) {

        if CSSearchableIndex.isIndexingAvailable() == false {
            DLOG("Indexing not available")
            return
        }

        let search = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
        search.city = station.city
        search.latitude = station.coordinateLat
        search.longitude = station.coordinateLon
        search.namedLocation = station.city
        search.displayName = station.stationName
        search.copyright = station.copyright
        search.keywords = ["kite", "surf", "wind", "fluid", "naish", "ozone", "f-one"]
        search.title = station.stationName
        search.contentDescription = station.city

        let url = "vindsiden://station/\(station.stationId!)"
        let item = CSSearchableItem(uniqueIdentifier: url, domainIdentifier: AppConfig.Bundle.appName, attributeSet: search)

        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems( [item], completionHandler: { (error: NSError?) -> Void in
            DLOG("Added station: \(station.stationName) with error: \(error?.localizedDescription)")
        })
    }


    public func removeStationFromIndex( station: CDStation ) {

        if CSSearchableIndex.isIndexingAvailable() == false {
            DLOG("Indexing not available")
            return
        }

        let url = "vindsiden://station/\(station.stationId!)"
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([url]) { (error: NSError?) -> Void in
            DLOG("Removed station: \(station.stationName) with error: \(error?.localizedDescription)")
        }
    }
    #endif


    lazy public var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return managedObjectContext
        }()


    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle(identifier: AppConfig.Bundle.frameworkBundleIdentifier)?.URLForResource(AppConfig.CoreData.datamodelName, withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
        }()



    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(AppConfig.CoreData.sqliteName)

        self.addSkipBackupAttributeToItemAtURL(url)

        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: AppConfig.Bundle.appName, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
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
                do {
                    try url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                } catch let error as NSError {
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
        _dateFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
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
