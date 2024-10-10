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

struct SinglePlotProvider: @preconcurrency AppIntentTimelineProvider  {
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
        let station = IntentStation.templateStation

        configuration.station = station

        return SinglePlotEntry(
            date: Date(),
            lastDate: Date(),
            configuration: configuration,
            widgetData: WidgetData(customIdentifier: "\(station.id)", name: station.name)
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SinglePlotEntry {
        let station = IntentStation.templateStation

        guard context.isPreview else {
            return SinglePlotEntry(
                date: Date(),
                lastDate: Date(),
                configuration: configuration,
                widgetData: WidgetData(customIdentifier: "\(station.id)", name: station.name)
            )
        }

        configuration.station = station

        return await Task { @MainActor in
            let fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])

            if let plot = try? PreviewSampleData.container.mainContext.fetch(fetchDescriptor).first {
                let temp: TempUnit = UserSettings.shared.selectedTempUnit
                let wind: WindUnit = UserSettings.shared.selectedWindUnit
                let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
                let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)
                let data = WidgetData(customIdentifier: "\(station.id)",
                                      name: station.name,
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
                    widgetData: WidgetData(customIdentifier: "\(station.id)", name: station.name)
                )
            }
        }.value
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SinglePlotEntry> {
        let station: IntentStation = configuration.station ?? .templateStation

        let entry: SinglePlotEntry = await Task {
            do {
                guard let widgetData = try await WidgetData.loadData(for: station.id, stationName: station.name) else {
                    return SinglePlotEntry(
                        date: Date(),
                        lastDate: Date(),
                        configuration: configuration,
                        widgetData: WidgetData(customIdentifier: "\(station.id)", name: station.name)
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
                    widgetData: WidgetData(customIdentifier: "\(station.id)", name: station.name)
                )
            }
        }.value

        return Timeline(entries: [entry], policy: .atEnd)
    }
}
