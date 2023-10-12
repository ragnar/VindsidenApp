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
    private let modelContainer: ModelContainer

    init() {
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.ApplicationGroups.primary) else {
            fatalError("Shared file container could not be created.")
        }

        let url = appGroupContainer.appendingPathComponent(AppConfig.CoreData.sqliteName)

        do {
            modelContainer = try ModelContainer(for: Station.self, Plot.self, configurations: ModelConfiguration(url: url))
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entries: [SimpleEntry] = await Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.dataId, order: .reverse)])
            fetchDescriptor.fetchLimit = 1

            if let plots = try? modelContainer.mainContext.fetch(fetchDescriptor), let plot = plots.first {
                print("plot", plot.dataId, plot.plotTime, plot.station?.stationName ?? "kk")
                return [
                    SimpleEntry(date: plot.plotTime, configuration: configuration)
                ]
            }
            return []
        }.value

        return Timeline(entries: entries, policy: .atEnd)
    }
}
