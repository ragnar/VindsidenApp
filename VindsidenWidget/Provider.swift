//
//  Provider.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftData
import VindsidenKit
import WeatherBoxView

struct Provider: AppIntentTimelineProvider  {
    private let modelContainer: ModelContainer = PersistentContainer.container

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), plots: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, plots: [])
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        guard let stationName = configuration.station else {
            return Timeline(entries: [], policy: .atEnd)
        }

        let entries: [SimpleEntry] = await Task { @MainActor in
            await WindManager.sharedManager.fetch()

            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
            fetchDescriptor.predicate = #Predicate { $0.station?.stationName == stationName }
            fetchDescriptor.fetchLimit = 20

            if let plots = try? modelContainer.mainContext.fetch(fetchDescriptor), let plot = plots.first {
                print("plot", plot.dataId, plot.plotTime, plot.station?.stationName ?? "kk", "plots:", plots.count)
                return [
                    SimpleEntry(date: plot.plotTime, configuration: configuration, plots: plots.reversed())
                ]
            }
            return []
        }.value

        return Timeline(entries: entries, policy: .atEnd)
    }
}
