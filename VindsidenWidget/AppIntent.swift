//
//  AppIntent.swift
//  VindsidenWidget
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import AppIntents
import SwiftData
import VindsidenKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    @Parameter(title: "Select station", optionsProvider: StationOptionsProvider())
    var station: String?

    struct StationOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.ApplicationGroups.primary) else {
                fatalError("Shared file container could not be created.")
            }

            let url = appGroupContainer.appendingPathComponent(AppConfig.CoreData.sqliteName)

            do {
                let modelContainer = try ModelContainer(for: Station.self, Plot.self, configurations: ModelConfiguration(url: url))

                return try await Task { @MainActor in
                    let fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.stationName, order: .forward)])

                    return try modelContainer.mainContext.fetch(fetchDescriptor).compactMap { $0.stationName }
                }.value
            } catch {
                fatalError("Failed to create the model container: \(error)")
            }
        }
    }
}

