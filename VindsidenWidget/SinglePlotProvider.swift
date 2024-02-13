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
import Units

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

struct SinglePlotProvider: AppIntentTimelineProvider  {
    @MainActor
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        var fetchDescriptor = FetchDescriptor(sortBy: [
            SortDescriptor(\Station.order, order: .forward),
            SortDescriptor(\Station.stationName, order: .forward),
        ])
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

        return SinglePlotEntry(
            date: Date(),
            lastDate: Date(),
            configuration: configuration,
            widgetData: WidgetData(customIdentifier: "-1", name: "Larkollen")
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SinglePlotEntry {
        guard context.isPreview else {
            return SinglePlotEntry(
                date: Date(),
                lastDate: Date(),
                configuration: configuration,
                widgetData: WidgetData(customIdentifier: "-1", name: "Larkollen")
            )
        }

        configuration.station = IntentStation(id: -1, name: "Larkollen")

        return await Task { @MainActor in
            let fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])

            if let plot = try? PreviewSampleData.container.mainContext.fetch(fetchDescriptor).first {
                let temp: TempUnit = UserSettings.shared.selectedTempUnit
                let wind: WindUnit = UserSettings.shared.selectedWindUnit
                let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
                let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)
                let data = WidgetData(customIdentifier: "-1",
                                      name: configuration.station.name,
                                      windAngle: Double(plot.windDir),
                                      windSpeed: Double(plot.windMin).fromUnit(.metersPerSecond).toUnit(wind),
                                      windAverage: Double(plot.windAvg).fromUnit(.metersPerSecond).toUnit(wind),
                                      windAverageMS: Double(plot.windAvg),
                                      windGust: Double(plot.windMax).fromUnit(.metersPerSecond).toUnit(wind),
                                      units: units,
                                      lastUpdated: plot.plotTime
                )

                return SinglePlotEntry(
                    date: Date(),
                    lastDate: Date(),
                    configuration: configuration,
                    widgetData: data
                )
            } else {
                return SinglePlotEntry(
                    date: Date(),
                    lastDate: Date(),
                    configuration: configuration,
                    widgetData: WidgetData(customIdentifier: "-1", name: "Larkollen")
                )
            }
        }.value
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SinglePlotEntry> {
        let entry: SinglePlotEntry = await Task {
            do {
                guard let widgetData = try await WidgetData.loadData(for: configuration.station.id, stationName: configuration.station.name) else {
                    return SinglePlotEntry(
                        date: Date(),
                        lastDate: Date(),
                        configuration: configuration,
                        widgetData: WidgetData(customIdentifier: "\(configuration.station.id)", name: configuration.station.name)
                    )
                }

                return SinglePlotEntry(
                    date: Date(),
                    lastDate: widgetData.lastUpdated,
                    configuration: configuration,
                    widgetData: widgetData
                )
            } catch {
                return SinglePlotEntry(
                    date: Date(),
                    lastDate: Date(),
                    configuration: configuration,
                    widgetData: WidgetData(customIdentifier: "\(configuration.station.id)", name: configuration.station.name)
                )
            }
        }.value

        return Timeline(entries: [entry], policy: .atEnd)
    }
}
