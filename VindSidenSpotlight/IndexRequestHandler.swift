//
//  IndexRequestHandler.swift
//  VindSidenSpotlight
//
//  Created by Ragnar Henriksen on 01.04.2016.
//  Copyright © 2016 RHC. All rights reserved.
//

import CoreSpotlight
import VindsidenKit
import OSLog

@MainActor
class IndexRequestHandler: CSIndexExtensionRequestHandler {
    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        let stations = Station.visible(in: PersistentContainer.shared.container.mainContext)

        for station in stations {
            DataManager.shared.addStationToIndex(station, index: searchableIndex)
        }

        acknowledgementHandler()
    }


    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        let context = PersistentContainer.shared.container.mainContext

        for identifier in identifiers {
            let stationIDString = (identifier as NSString).lastPathComponent

            if let stationID = Int(stationIDString) {
                guard let station = Station.existing(for: stationID, in: context) else {
                    searchableIndex.deleteSearchableItems(withIdentifiers: [identifier], completionHandler: { (error) in
                        Logger.debugging.debug("Error: \(String(describing: error))")
                    })
                    continue
                }

                if station.isHidden {
                    DataManager.shared.removeStationFromIndex(station, index: searchableIndex)
                } else {
                    DataManager.shared.addStationToIndex(station, index: searchableIndex)
                }
            }
        }

        acknowledgementHandler()
    }
}
