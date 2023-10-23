//
//  WidgetData.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import VindsidenKit
import WeatherBoxView
import Units

extension WidgetData {
    @MainActor
    static func loadData(for stationId: Int) async throws -> WidgetData? {
        await WindManager.sharedManager.fetch()

        let modelContainer: ModelContainer = PersistentContainer.shared.container
        let gregorian = NSCalendar(identifier: .gregorian)!
        let inDate = Date().addingTimeInterval(-1*AppConfig.Global.plotHistory*3600)

        let stationId32 = Int32(stationId)

        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
        fetchDescriptor.predicate = #Predicate { $0.station?.stationId == stationId32 }
        fetchDescriptor.fetchLimit = 1

        guard 
            let plots = try? modelContainer.mainContext.fetch(fetchDescriptor),
            let plot = plots.first
        else {
            return nil
        }

        let name = plot.station?.stationName ?? "Unknown"
        let temp: TempUnit = UserSettings.shared.selectedTempUnit
        let wind: WindUnit = UserSettings.shared.selectedWindUnit
        let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
        let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)
        let data = WidgetData(name: name,
                              windAngle: Double(plot.windDir),
                              windSpeed: Double(plot.windMin).toUnit(wind),
                              windAverage: Double(plot.windAvg).toUnit(wind),
                              windAverageMS: Double(plot.windAvg),
                              windGust: Double(plot.windMax).toUnit(wind),
                              units: units,
                              lastUpdated: plot.plotTime
        )

        return data
    }
}
