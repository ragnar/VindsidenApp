//
//  StationModelActor.swift
//  VindsidenKit
//
//  Created by Ragnar Henriksen on 28/11/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import OSLog

@ModelActor
public actor StationModelActor {
    public func updateWithFetchedContent(_ content: [[String: String]]) -> Bool {
        let stationIds = content.map { return Int($0["StationID"]!)! }

        removeStaleStations(stationIds)

        var inserted = false
        var order = Station.maxOrder(in: modelContext) ?? 200

        for stationContent in content {
            guard
                let stationIdString = stationContent["StationID"],
                let stationId = Int(stationIdString)
            else {
                Logger.persistence.debug("No stationId")
                continue
            }

            let station: Station

            if let existing = Station.existing(for: stationId, in: modelContext) {
                station = existing
            } else {
                inserted = true
                station = Station()

                if stationId == 60 {
                    station.order = 101
                    station.isHidden = false
                } else {
                    order += 1
                    station.order = order
                }

                modelContext.insert(station)
            }

            station.updateWithContent(stationContent, stationId: stationId)
        }

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save failed: \(error.localizedDescription)")
        }

        return inserted
    }

    public func updateWithWatchContent(_ content: [[String: AnyObject]]) async {
        let stationIds = content.map { return $0["stationId"] as! Int }

        removeStaleStations(stationIds)

        for stationContent in content {
            guard let stationId = stationContent["stationId"] as? Int else {
                Logger.persistence.debug("No stationId")
                continue
            }

            let station: Station

            if let existing = Station.existing(for: stationId, in: modelContext) {
                station = existing
            } else {
                station = Station()
                modelContext.insert(station)
            }

            station.updateWithWatchContent(stationContent)
        }

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save failed: \(error.localizedDescription)")
        }
    }

    func removeStaleStations(_ stations: [Int]) {
        do {
            let predicate = #Predicate<Station> { station in
                stations.contains(station.stationId) == false
            }

            try modelContext.delete(model: Station.self, where: predicate)

            Logger.persistence.debug("Deleted \(self.modelContext.deletedModelsArray.count) stations")

            try modelContext.save()
        } catch {
            Logger.persistence.error("Deleting failed: \(error.localizedDescription)")
        }
    }}
