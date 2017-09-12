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
open class Datamanager : NSObject
{
    let _formatterQueue: DispatchQueue = DispatchQueue(label: "formatter queue", attributes: [])

    open static let sharedManager = Datamanager()


    public required override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(Datamanager.mainManagedObjectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedObjectContext)
    }


    func mainManagedObjectContextDidSave(_ notification: Notification) -> Void {
        DLOG("Saving MOC based on notification")
        managedObjectContext.mergeChanges(fromContextDidSave: notification)
    }


    open func saveContext () {
        if self.managedObjectContext.hasChanges {
            do {
                try self.managedObjectContext.save()
            } catch let error as NSError {
                NSLog("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }


    open func cleanupPlots(_ completionHandler: (() -> Void)? = nil) -> Void {

        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = managedObjectContext
        childContext.mergePolicy = NSRollbackMergePolicy;
        childContext.undoManager = nil

        childContext.perform { () -> Void in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPlot")
            let interval: TimeInterval = -1.0*((1.0+AppConfig.Global.plotHistory)*3600.0)
            let time = Date(timeIntervalSinceNow: interval)
            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time as CVarArg)

            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            request.resultType = .resultTypeCount
            do {
                let result = try childContext.execute(request) as! NSBatchDeleteResult
                DLOG("Deleted \(result.result!) plots")

                try childContext.save()

                childContext.processPendingChanges()

                self.managedObjectContext.perform {
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


    open func removeStaleStationsIds( _ stations: [Int], inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Void {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStation")
        fetchRequest.predicate = NSPredicate(format: "NOT stationId IN (%@)", stations)

        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        request.resultType = .resultTypeCount

        do {
            let result = try managedObjectContext.execute(request) as! NSBatchDeleteResult
            DLOG("Deleted \(result.result!) station(s)")
        } catch {
            DLOG("Delete failed: \(error)")
        }
    }


    #if os(iOS)

    open func indexVisibleStations( ) {
        AppConfig.sharedConfiguration.shouldIndexForFirstTime() {
            let index: CSSearchableIndex = CSSearchableIndex.default()

            for station in CDStation.visibleStationsInManagedObjectContext(self.managedObjectContext) {
                self.addStationToIndex(station, index: index)
            }
        }
    }


    open func addStationToIndex( _ station: CDStation, index: CSSearchableIndex = CSSearchableIndex.default() ) {

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

        CSSearchableIndex.default().indexSearchableItems( [item], completionHandler: { (error: Error?) -> Void in
            DLOG("Added station: \(String(describing: station.stationName)) with error: \(String(describing: error?.localizedDescription))")
        })
    }


    open func removeStationFromIndex( _ station: CDStation, index: CSSearchableIndex = CSSearchableIndex.default() ) {

        if CSSearchableIndex.isIndexingAvailable() == false {
            DLOG("Indexing not available")
            return
        }

        let url = "vindsiden://station/\(station.stationId!)"
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [url]) { (error: Error?) -> Void in
            DLOG("Removed station: \(String(describing: station.stationName)) with error: \(String(describing: error?.localizedDescription))")
        }
    }
    #endif


    lazy open var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return managedObjectContext
        }()


    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle(identifier: AppConfig.Bundle.frameworkBundleIdentifier)?.url(forResource: AppConfig.CoreData.datamodelName, withExtension: "momd")
        return NSManagedObjectModel(contentsOf: modelURL!)!
        }()



    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(AppConfig.CoreData.sqliteName)

        self.addSkipBackupAttributeToItemAtURL(url)

        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: AppConfig.Bundle.appName, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
        }()


    var applicationDocumentsDirectory: URL {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.ApplicationGroups.primary)
        if let actualurl = url {
            return actualurl as URL
        } else {
            return URL(string: "FIXME")!
        }
    }


    func addSkipBackupAttributeToItemAtURL( _ url: URL) -> Void {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try (url as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
            } catch let error as NSError {
                NSLog("Error excluding \(url.lastPathComponent) from backup \(error)");
            }
        }
    }


    var dateFormatter: DateFormatter {
        if let actdate = _dateFormatter {
            return actdate
        }

        _dateFormatter = DateFormatter()
        _dateFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        _dateFormatter!.timeZone = TimeZone(identifier: "UTC")
        return _dateFormatter!
    }
    var _dateFormatter: DateFormatter? = nil


    open func dateFromString(_ string: String) -> Date!
    {
        var date: Date? = nil
        _formatterQueue.sync {
            date = self.dateFormatter.date(from: string)
        };

        return date ?? Date.init(timeIntervalSince1970: 0)
    }
}
