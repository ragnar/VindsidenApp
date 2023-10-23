//
//  SinglePlotProvider.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftData
import VindsidenKit
import WeatherBoxView

struct SinglePlotProvider: AppIntentTimelineProvider  {
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
