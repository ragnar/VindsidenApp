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
    static var description = IntentDescription("Select wind station to show in the widget.")

    @Parameter(title: "Select station", optionsProvider: StationOptionsProvider())
    var station: String?

    struct StationOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            do {
                return try await Task { @MainActor in
                    var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.stationName, order: .forward)])
                    fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

                    return try PersistentContainer.container.mainContext.fetch(fetchDescriptor).compactMap { $0.stationName }
                }.value
            } catch {
                fatalError("Failed to create the model container: \(error)")
            }
        }
    }
}
