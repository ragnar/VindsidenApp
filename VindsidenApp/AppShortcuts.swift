//
//  AppShortcuts.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 19/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//


import AppIntents
import SwiftUI
import SwiftData
import VindsidenKit
import WeatherBoxView
import Units

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: OpenWindStationIntent(),
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

    static var shortcutTileColor: ShortcutTileColor = .orange
}

struct OpenWindStationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Open Station"
    static var description = IntentDescription("Open the application at chosen wind station")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Select station")
    var station: IntentStation

    @Dependency
    private var navigationModel: NavigationModel

    init() {
        IntentStation.defaultQuery = StationQuery(useDefaultValue: false)
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        navigationModel.pendingSelectedStationName = station.name

        return .result()
    }
}

struct ShowWindStatus: AppIntent {
    static var title: LocalizedStringResource = "Show wind"
    static var description = IntentDescription("Shows the current wind data for chosen wind station.")

    @Parameter(title: "Station")
    var station: IntentStation

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        try? await WindManager.shared.fetch(stationId: station.id)

        let stationId = station.id
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.plotTime, order: .reverse)])
        fetchDescriptor.predicate = #Predicate { $0.station?.stationId == stationId }
        fetchDescriptor.fetchLimit = 1

        if let plots = try? PersistentContainer.shared.container.mainContext.fetch(fetchDescriptor), let plot = plots.first {
            let temp: TempUnit = UserSettings.shared.selectedTempUnit
            let wind: WindUnit = UserSettings.shared.selectedWindUnit
            let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
            let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)

            let info = WidgetData(customIdentifier: "\(station.id)",
                                  name: station.name,
                                  windAngle: Double(plot.windDir),
                                  windSpeed: Double(plot.windMin),
                                  windAverage: Double(plot.windAvg),
                                  windAverageMS: Double(plot.windAvg),
                                  windGust: Double(plot.windMax),
                                  units: units,
                                  lastUpdated: plot.plotTime)

            return .result(view: IntentWindView(info: info))
        } else {
            return .result()
        }
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
