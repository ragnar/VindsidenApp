//
//  Datamanager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import Foundation
import OSLog

#if os(iOS)
import MobileCoreServices
import CoreSpotlight
#endif

public final class DataManager: NSObject, @unchecked Sendable {
    @objc public static let shared = DataManager()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        formatter.timeZone = TimeZone(identifier: "UTC")

        return formatter
    }()
}


extension DataManager {
    func dateFromString(_ string: String) -> Date! {
        return dateFormatter.date(from: string)
    }

    public func cleanupPlots(_ completionHandler: (() -> Void)? = nil) {
//        performBackgroundTask { (context) in
//            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPlot.fetchRequest()
//            let interval: TimeInterval = -1.0 * AppConfig.Global.plotHistory * 3600.0
//            let time = Date(timeIntervalSinceNow: interval)
//            
//            fetchRequest.predicate = NSPredicate(format: "plotTime < %@", time as CVarArg)
//
//            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//            request.resultType = .resultTypeCount
//
//            do {
//                let result = try context.execute(request) as! NSBatchDeleteResult
//                Logger.persistence.debug("Deleted \(result.result as? Int ?? -1) plots")
//
//                try context.save()
//
//                DispatchQueue.main.async {
//                    completionHandler?()
//                }
//            } catch {
//                Logger.persistence.debug("Save failed: \(error)")
//
//                DispatchQueue.main.async {
//                    completionHandler?()
//                }
//            }
//        }
    }

#if os(iOS)
    @objc public func indexVisibleStations() {
        guard AppConfig.shared.shouldIndexForFirstTime() else {
            return
        }

        Task { @MainActor in
            let index = CSSearchableIndex.default()
            let context = PersistentContainer.shared.container.mainContext
            let stations = Station.visible(in: context)

            for station in stations {
                self.addStationToIndex(station, index: index)
            }
        }
    }

    public func addStationToIndex(_ station: Station, index: CSSearchableIndex = CSSearchableIndex.default()) {
        guard CSSearchableIndex.isIndexingAvailable() else {
            Logger.persistence.debug("Indexing not available")
            return
        }

        let lookupKey = CSCustomAttributeKey(keyName: "lookupKey", searchable: false, searchableByDefault: false, unique: true, multiValued: false)!
        let search = CSSearchableItemAttributeSet(contentType: .content)
        search.city = station.city

        if let lat = station.coordinateLat, let lon = station.coordinateLon {
            search.latitude = NSNumber(floatLiteral: lat)
            search.longitude = NSNumber(floatLiteral: lon)
        }

        search.namedLocation = station.city
        search.displayName = station.stationName
        search.copyright = station.copyright
        search.keywords = ["kite", "surf", "wind", "fluid", "naish", "ozone", "f-one"]
        search.title = station.stationName
        search.contentDescription = station.city
        search.setValue(station.stationName as? NSString, forCustomKey: lookupKey)

        let url = "vindsiden://station/\(station.stationId)"
        let item = CSSearchableItem(uniqueIdentifier: url, domainIdentifier: AppConfig.Bundle.appName, attributeSet: search)
        let stationName = station.stationName

        CSSearchableIndex.default().indexSearchableItems( [item], completionHandler: { (error: Error?) -> Void in
            Logger.persistence.debug("Added station: \(String(describing: stationName)) with error: \(String(describing: error?.localizedDescription))")
        })
    }

    public func removeStationFromIndex(_ station: Station, index: CSSearchableIndex = CSSearchableIndex.default()) {
        guard CSSearchableIndex.isIndexingAvailable() else {
            Logger.persistence.debug("Indexing not available")
            return
        }

        let stationName = station.stationName
        let url = "vindsiden://station/\(station.stationId)"

        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [url]) { (error: Error?) -> Void in
            Logger.persistence.debug("Removed station: \(String(describing: stationName)) with error: \(String(describing: error?.localizedDescription))")
        }
    }
#endif
}
