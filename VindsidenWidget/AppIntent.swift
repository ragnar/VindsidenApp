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

struct ConfigurationAppIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "View station"
    static var description = IntentDescription("Select wind station to show in the widget.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Select station")
    var station: IntentStation?

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct IntentStation: AppEntity, Hashable {
    var id: Int
    var name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(stringLiteral: "Station")

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(stringLiteral: name)
    }

    static var defaultQuery = StationQuery()
}

struct StationQuery: EntityQuery {
    func entities(for identifiers: [IntentStation.ID]) async throws -> [IntentStation] {
        return try await Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.stationName, order: .forward)])
            fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

            return try PersistentContainer
                .container
                .mainContext
                .fetch(fetchDescriptor)
                .filter { identifiers.contains($0.stationId) }
                .compactMap { IntentStation(id: $0.stationId, name: $0.stationName ?? "") }
        }.value
    }

    func suggestedEntities() async throws -> [IntentStation] {
        return try await Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.stationName, order: .forward)])
            fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

            return try PersistentContainer.container.mainContext.fetch(fetchDescriptor).compactMap { IntentStation(id: $0.stationId, name: $0.stationName ?? "") }
        }.value
    }
}
