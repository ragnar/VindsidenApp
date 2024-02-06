//
//  PlotModelActor.swift
//  VindsidenKit
//
//  Created by Ragnar Henriksen on 28/11/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import OSLog

@ModelActor
public actor PlotModelActor {
    public func updatePlots(_ plots: [[String: String]]) async throws -> Int {
        guard
            let stationPlot = plots.first,
            let stationString = stationPlot["StationID"],
            let stationId = Int(stationString),
            let station = Station.existing(for: stationId, in: modelContext)
        else {
            return 0
        }

        modelContext.autosaveEnabled = true

        for plotContent in plots {
            guard
                let unwrapped = plotContent["DataID"],
                let dataId = Int(unwrapped),
                Plot.existing(for: dataId, with: stationId, in: modelContext) == nil
            else {
                continue
            }

            let plot = Plot()

            plot.updateWithContent(plotContent)
            plot.station = station

            modelContext.insert(plot)
        }

        let numInserted = modelContext.insertedModelsArray.count

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save plot failed: \(error.localizedDescription)")
        }

        return numInserted
    }
}
