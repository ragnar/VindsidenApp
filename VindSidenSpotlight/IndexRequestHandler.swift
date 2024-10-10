//
//  IndexRequestHandler.swift
//  VindSidenSpotlight
//
//  Created by Ragnar Henriksen on 01.04.2016.
//  Copyright © 2016 RHC. All rights reserved.
//

@preconcurrency import CoreSpotlight
import VindsidenKit
import OSLog

final class IndexRequestHandler: CSIndexExtensionRequestHandler {
    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping @Sendable () -> Void) {
        Task.detached { @MainActor in
            let context = PersistentContainer.shared.container.mainContext
            let stations = Station.visible(in: context)


            for station in stations {
                DataManager.shared.addStationToIndex(station, index: searchableIndex)
            }

            acknowledgementHandler()
        }
    }


    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            let context =  PersistentContainer.shared.container.mainContext

            for identifier in identifiers {
                let stationIDString = (identifier as NSString).lastPathComponent

                if let stationID = Int(stationIDString) {
                    guard let station = Station.existing(for: stationID, in: context) else {
                        do {
                            try await searchableIndex.deleteSearchableItems(withIdentifiers: [identifier])
                        } catch {
                            Logger.debugging.debug("Error: \(error)")
                        }
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
}
