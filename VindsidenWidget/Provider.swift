//
//  Provider.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftData
import WeatherBoxView
import OSLog

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

struct Provider: AppIntentTimelineProvider  {
    func placeholder(in context: Context) -> SimpleEntry {
        let configuration = ConfigurationAppIntent()

        configuration.station = IntentStation(id: -1, name: "Larkollen")

        return SimpleEntry(
            date: Date(),
            lastDate: Date(),
            configuration: configuration,
            plots: []
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        guard context.isPreview else {
            return SimpleEntry(
                date: Date(),
                lastDate: Date(),
                configuration: configuration,
                plots: []
            )
        }

        let plots = await Task { @MainActor in
            let fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
            let plots = try? PreviewSampleData.container.mainContext.fetch(fetchDescriptor)

            return plots ?? []
        }.value

        configuration.station = IntentStation(id: -1, name: "Larkollen")

        return SimpleEntry(
            date: Date(),
            lastDate: Date(),
            configuration: configuration,
            plots: plots
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let stationId = configuration.station.id
        let entries: [SimpleEntry] = await Task { @MainActor in
            try? await WindManager.shared.fetch(stationId: stationId)

            let modelContainer: ModelContainer = PersistentContainer.shared.container
            let gregorian = NSCalendar(identifier: .gregorian)!
            let inDate = Date.now.addingTimeInterval(-1*AppConfig.Global.plotHistory*3600)
            let inputComponents = gregorian.components([.year, .month, .day, .hour], from: inDate)
            let outDate = gregorian.date(from: inputComponents) ?? Date()

            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
            fetchDescriptor.predicate = #Predicate { $0.station?.stationId == stationId }
            fetchDescriptor.fetchLimit = 20

            if let plots = try? modelContainer.mainContext.fetch(fetchDescriptor), let plot = plots.first {
                Logger.debugging.debug("plot \(plot.dataId), \(plot.plotTime), \(plot.station?.stationName ?? "kk"), plots:, \(plots.count)")
                return [
                    SimpleEntry(date: Date(), 
                                lastDate: plot.plotTime,
                                configuration: configuration,
                                plots: plots.filter { $0.plotTime >= outDate }.reversed()
                               )
                ]
            }
            return []
        }.value

        return Timeline(entries: entries, policy: .atEnd)
    }
}
