//
//  IndexRequestHandler.swift
//  VindSidenSpotlight
//
//  Created by Ragnar Henriksen on 01.04.2016.
//  Copyright © 2016 RHC. All rights reserved.
//

import CoreSpotlight
import VindsidenKit


class IndexRequestHandler: CSIndexExtensionRequestHandler {

    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        let managedObjectContext = DataManager.shared.viewContext()

        for station in CDStation.visibleStationsInManagedObjectContext(managedObjectContext) {
            DataManager.shared.addStationToIndex(station, index: searchableIndex)
        }

        acknowledgementHandler()
    }


    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        let managedObjectContext = DataManager.shared.viewContext()

        for identifier in identifiers {
            do {
                let stationIDString = (identifier as NSString).lastPathComponent

                if let stationID = Int(stationIDString) {
                    let station = try CDStation.existingStationWithId(stationID, inManagedObjectContext: managedObjectContext)

                    if let hidden = station.isHidden, hidden.boolValue == false {
                        DataManager.shared.addStationToIndex(station, index: searchableIndex)
                    } else {
                        DataManager.shared.removeStationFromIndex(station, index: searchableIndex)
                    }
                }
            } catch {
                searchableIndex.deleteSearchableItems(withIdentifiers: [identifier], completionHandler: { (error) in
                    DLOG("Error: \(String(describing: error))")
                })

                continue
            }
        }

        acknowledgementHandler()
    }
}
