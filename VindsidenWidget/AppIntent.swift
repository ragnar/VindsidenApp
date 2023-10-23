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
                .shared
                .container
                .mainContext
                .fetch(fetchDescriptor)
                .filter { identifiers.contains(Int($0.stationId!)) }
                .compactMap { IntentStation(id: Int($0.stationId!), name: $0.stationName ?? "") }
        }.value
    }

    func suggestedEntities() async throws -> [IntentStation] {
        return try await Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.stationName, order: .forward)])
            fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

            return try PersistentContainer.shared.container.mainContext.fetch(fetchDescriptor).compactMap { IntentStation(id: Int($0.stationId!), name: $0.stationName ?? "") }
        }.value
    }

    func defaultResult() async -> IntentStation? {
#if MAINAPP
        return nil
#else
        return try? await suggestedEntities().first
#endif
    }
}
