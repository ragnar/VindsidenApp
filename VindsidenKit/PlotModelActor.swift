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
import WeatherBoxView
import Units

@ModelActor
public actor PlotModelActor {
    public func updatePlots(_ plots: [[String: String]]) async throws -> Int {
        guard
            let stationPlot = plots.first,
            let stationString = stationPlot["StationID"],
            let stationId = Int(stationString)
        else {
            return 0
        }

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

    public func widgetData(for stationId: Int, stationName: String) async throws -> WidgetData? {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
        fetchDescriptor.predicate = #Predicate { $0.stationId == stationId }
        fetchDescriptor.fetchLimit = 1

        let plots = try modelContext.fetch(fetchDescriptor)

        guard let plot = plots.first else {
            return nil
        }

        let stationId: String? = "\(stationId)"

        let temp: TempUnit = UserSettings.shared.selectedTempUnit
        let wind: WindUnit = UserSettings.shared.selectedWindUnit
        let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
        let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)
        let data = WidgetData(customIdentifier: stationId,
                              name: stationName,
                              windAngle: Double(plot.windDir),
                              windSpeed: Double(plot.windMin).fromUnit(.metersPerSecond).toUnit(wind),
                              windAverage: Double(plot.windAvg).fromUnit(.metersPerSecond).toUnit(wind),
                              windAverageMS: Double(plot.windAvg),
                              windGust: Double(plot.windMax).fromUnit(.metersPerSecond).toUnit(wind),
                              units: units,
                              lastUpdated: plot.plotTime
        )

        return data
    }
}
