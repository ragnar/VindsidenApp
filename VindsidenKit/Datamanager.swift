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

@objc
open class DataManager: NSObject {

    @objc public static let shared = DataManager()

    let _formatterQueue: DispatchQueue = DispatchQueue(label: "formatter queue", attributes: [])


    override init() {
        super.init()
        viewContext().automaticallyMergesChangesFromParent = true
    }


    @objc open func viewContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }


    open func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.viewContext.perform {
            block(self.persistentContainer.viewContext)
        }
    }


    open func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }


    // MARK: - Core Data Saving support


    open func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


    // MARK: - Core Data stack


    fileprivate lazy var persistentContainer: NSPersistentContainer = {
        /*
         Need to manually set up the model, since it is placed inside a framework
         */
        let modelURL = Bundle(for: DataManager.self).url(forResource: AppConfig.CoreData.datamodelName, withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)!
        let container = NSPersistentContainer(name: AppConfig.CoreData.datamodelName, managedObjectModel: model)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(AppConfig.CoreData.sqliteName)
        let description = NSPersistentStoreDescription(url: url)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]

        self.addSkipBackupAttributeToItemAtURL(url)


        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()


    open func cleanupPlots(_ completionHandler: (() -> Void)? = nil) -> Void {
        performBackgroundTask { (context) in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPlot.fetchRequest()
            let interval: TimeInterval = -1.0*((1.0+AppConfig.Global.plotHistory)*3600.0)
            let time = Date(timeIntervalSinceNow: interval)
            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time as CVarArg)

            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            request.resultType = .resultTypeCount

            do {
                let result = try context.execute(request) as! NSBatchDeleteResult
                DLOG("Deleted \(result.result!) plots")

                try context.save()
                completionHandler?()
            } catch {
                DLOG("Save failed: \(error)")
                completionHandler?()
            }
        }
    }


    open func removeStaleStationsIds( _ stations: [Int], inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Void {
        performBackgroundTask { (context) in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDStation.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "NOT stationId IN (%@)", stations)

            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            request.resultType = .resultTypeCount

            do {
                let result = try managedObjectContext.execute(request) as! NSBatchDeleteResult
                DLOG("Deleted \(result.result!) station(s)")
                try context.save()
            } catch {
                DLOG("Delete failed: \(error)")
            }
        }
    }


    // MARK: - Spotlight


    #if os(iOS)

    @objc open func indexVisibleStations( ) {
        AppConfig.sharedConfiguration.shouldIndexForFirstTime() {
            let index: CSSearchableIndex = CSSearchableIndex.default()

            performBackgroundTask { (context) in
                for station in CDStation.visibleStationsInManagedObjectContext(context) {
                    self.addStationToIndex(station, index: index)
                }
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


    // MARK: - File


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


    // MARK: - Date Formatting


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
