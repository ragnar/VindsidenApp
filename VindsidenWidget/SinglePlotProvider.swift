//
//  SinglePlotProvider.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftData
import WeatherBoxView

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

struct SinglePlotProvider: AppIntentTimelineProvider  {
    @MainActor
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.stationName, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

        do {
            return try PersistentContainer
                .shared
                .container
                .mainContext
                .fetch(fetchDescriptor)
                .compactMap {
                    let intent = ConfigurationAppIntent()
                    let station = IntentStation(id: Int($0.stationId), name: $0.stationName ?? "")

                    intent.station = station

                    return AppIntentRecommendation(intent: intent,
                                                   description: $0.stationName!)
                }
        } catch {
            return []
        }
    }

    func placeholder(in context: Context) -> SinglePlotEntry {
        let configuration = ConfigurationAppIntent()

        configuration.station = IntentStation(id: -1, name: "Larkollen")

        return SinglePlotEntry(date: Date(), configuration: configuration, widgetData: WidgetData())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SinglePlotEntry {
        do {
            guard let widgetData = try await WidgetData.loadData(for: configuration.station.id) else {
                return SinglePlotEntry(date: Date(), configuration: configuration, widgetData: WidgetData())
            }

            return SinglePlotEntry(date: Date(), configuration: configuration, widgetData: widgetData)
        } catch {
            return SinglePlotEntry(date: Date(), configuration: configuration, widgetData: WidgetData())
        }
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SinglePlotEntry> {
        let snapshot = await snapshot(for: configuration, in: context)

        return Timeline(entries: [snapshot], policy: .atEnd)
    }
}
