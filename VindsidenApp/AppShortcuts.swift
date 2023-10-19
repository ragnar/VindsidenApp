//
//  AppShortcuts.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 19/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//


import AppIntents
import SwiftUI
import VindsidenKit
import WeatherBoxView
import Units

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: ConfigurationAppIntent(),
                phrases: [
                    "Open wind station in \(.applicationName)",
                ],
                shortTitle: "Open",
                systemImageName: "wind"
            ),
            AppShortcut(
                intent: ShowWindStatus(),
                phrases: [
                    "How is the wind in \(.applicationName)",
                ],
                shortTitle: "Show",
                systemImageName: "wind"
            ),
        ]
    }
}

struct ShowWindStatus: AppIntent {
    static var title: LocalizedStringResource = "Show wind"
    static var description = IntentDescription("Shows the current wind data for chosen wind station.")

    @Parameter(title: "Station")
    var station: IntentStation

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        await WindManager.sharedManager.fetch()

        guard
            let gregorian = NSCalendar(identifier: .gregorian),
            let currentStation = try? CDStation.existingStationWithId(station.id, inManagedObjectContext: DataManager.shared.viewContext()),
            let context = currentStation.managedObjectContext
        else {
            return .result()
        }

        let inDate = Date().addingTimeInterval(-1*AppConfig.Global.plotHistory*3600)
        let inputComponents = gregorian.components([.year, .month, .day, .hour], from: inDate)
        let outDate = gregorian.date(from: inputComponents) ?? Date()

        let fetchRequest = CDPlot.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "station == %@ AND plotTime >= %@", currentStation, outDate as CVarArg)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "plotTime", ascending: false),
        ]

        let plot: CDPlot? = ((try? context.fetch(fetchRequest)) ?? []).first

        guard let plot else {
            return .result()
        }

        let temp: TempUnit = UserSettings.shared.selectedTempUnit
        let wind: WindUnit = UserSettings.shared.selectedWindUnit
        let direction = DirectionUnit(rawValue: plot.windDir?.doubleValue ?? 0) ?? .unknown
        let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)

        let info = WidgetData(name: station.name,
                              windAngle: plot.windDir?.doubleValue ?? 0,
                              windSpeed: plot.windMin?.doubleValue ?? 0,
                              windAverage: plot.windAvg?.doubleValue ?? 0,
                              windAverageMS: plot.windAvg?.doubleValue ?? 0,
                              windGust: plot.windMax?.doubleValue ?? 0,
                              units: units,
                              lastUpdated: plot.plotTime ?? Date())

        return .result(view: IntentWindView(info: info))
    }
}

struct IntentWindView: View {
    var info: WidgetData

    var body: some View {
        WeatherBoxView(data: info, timeStyle: .relative, useBaro: false)
            .frame(maxWidth: 200)
            .scenePadding()
    }
}
