//
//  Datamanager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation
import CoreData
import OSLog

#if os(iOS)
import MobileCoreServices
import CoreSpotlight
#endif

@objc
public class DataManager: NSObject {
    @objc public static let shared = DataManager()

    let container: NSPersistentContainer
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        formatter.timeZone = TimeZone(identifier: "UTC")

        return formatter
    }()

    init(inMemory: Bool = false) {
        guard let modelURL = Bundle(for: DataManager.self).url(forResource: AppConfig.CoreData.datamodelName, withExtension: "momd") else {
            fatalError("Unable to find data model in the bundle.")
        }

        guard let coreDataModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to create the Core Data model.")
        }

        container = NSPersistentContainer(name: AppConfig.CoreData.datamodelName, managedObjectModel: coreDataModel)

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.ApplicationGroups.primary) else {
                fatalError("Shared file container could not be created.")
            }

            let url = appGroupContainer.appendingPathComponent(AppConfig.CoreData.sqliteName)

            if let description = container.persistentStoreDescriptions.first {
                description.url = url
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            }
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}


extension DataManager {
    @objc public func viewContext() -> NSManagedObjectContext {
        return container.viewContext
    }

    public func saveContext() {
        do {
            try container.viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            block(context)
        }
    }

    func dateFromString(_ string: String) -> Date! {
        return dateFormatter.date(from: string)
    }

    public func cleanupPlots(_ completionHandler: (() -> Void)? = nil) {
        performBackgroundTask { (context) in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPlot.fetchRequest()
            let interval: TimeInterval = -1.0 * AppConfig.Global.plotHistory * 3600.0
            let time = Date(timeIntervalSinceNow: interval)
            
            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time as CVarArg)

            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            request.resultType = .resultTypeCount

            do {
                let result = try context.execute(request) as! NSBatchDeleteResult
                Logger.persistence.debug("Deleted \(result.result as? Int ?? -1) plots")

                try context.save()

                DispatchQueue.main.async {
                    completionHandler?()
                }
            } catch {
                Logger.persistence.debug("Save failed: \(error)")

                DispatchQueue.main.async {
                    completionHandler?()
                }
            }
        }
    }

#if os(iOS)
    @objc public func indexVisibleStations() {
        guard AppConfig.sharedConfiguration.shouldIndexForFirstTime() else {
            return
        }

        let index: CSSearchableIndex = CSSearchableIndex.default()

        performBackgroundTask { (context) in
            for station in CDStation.visibleStationsInManagedObjectContext(context) {
                self.addStationToIndex(station, index: index)
            }
        }
    }
    
    public func addStationToIndex(_ station: CDStation, index: CSSearchableIndex = CSSearchableIndex.default()) {
        guard CSSearchableIndex.isIndexingAvailable() else {
            Logger.persistence.debug("Indexing not available")
            return
        }

        let search = CSSearchableItemAttributeSet(contentType: .content)
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
        let stationName = station.stationName

        CSSearchableIndex.default().indexSearchableItems( [item], completionHandler: { (error: Error?) -> Void in
            Logger.persistence.debug("Added station: \(String(describing: stationName)) with error: \(String(describing: error?.localizedDescription))")
        })
    }

    public func removeStationFromIndex(_ station: CDStation, index: CSSearchableIndex = CSSearchableIndex.default()) {
        guard CSSearchableIndex.isIndexingAvailable() else {
            Logger.persistence.debug("Indexing not available")
            return
        }

        let stationName = station.stationName
        let url = "vindsiden://station/\(station.stationId!)"
        
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [url]) { (error: Error?) -> Void in
            Logger.persistence.debug("Removed station: \(String(describing: stationName)) with error: \(String(describing: error?.localizedDescription))")
        }
    }
#endif
}
