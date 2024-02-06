//
//  WidgetData.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import WeatherBoxView
import Units

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

extension WidgetData {
    @MainActor
    static func loadData(for stationId: Int, stationName: String) async throws -> WidgetData? {
        try? await WindManager.shared.fetch(station: (stationId, stationName))

        let modelContainer: ModelContainer = PersistentContainer.shared.container

        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
        fetchDescriptor.predicate = #Predicate { $0.station?.stationId == stationId }
        fetchDescriptor.fetchLimit = 1

        guard 
            let plots = try? modelContainer.mainContext.fetch(fetchDescriptor),
            let plot = plots.first
        else {
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
