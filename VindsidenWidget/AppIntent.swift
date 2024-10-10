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

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

struct IntentStation: AppEntity, Hashable {
    var id: Int
    var name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(stringLiteral: "Station")

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(stringLiteral: name)
    }

    // FIXME: Why do I need to use default value some times?
    static let defaultQuery = StationQuery(useDefaultValue: false)

    static let templateStation = IntentStation(id: 4700, name: "Tønsvika")
}

struct StationQuery: EntityQuery {
    var useDefaultValue = true

    func entities(for identifiers: [IntentStation.ID]) async throws -> [IntentStation] {
        return try await Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [
                SortDescriptor(\Station.order, order: .forward),
                SortDescriptor(\Station.stationName, order: .forward),
            ])
            fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

            return try PersistentContainer
                .shared
                .container
                .mainContext
                .fetch(fetchDescriptor)
                .filter { identifiers.contains(Int($0.stationId)) }
                .compactMap { IntentStation(id: Int($0.stationId), name: $0.stationName ?? "") }
        }.value
    }

    func suggestedEntities() async throws -> [IntentStation] {
        return try await Task { @MainActor in
            var fetchDescriptor = FetchDescriptor(sortBy: [
                SortDescriptor(\Station.order, order: .forward),
                SortDescriptor(\Station.stationName, order: .forward),
            ])
            fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

            return try PersistentContainer.shared.container.mainContext.fetch(fetchDescriptor).compactMap { IntentStation(id: Int($0.stationId), name: $0.stationName ?? "") }
        }.value
    }

    func defaultResult() async -> IntentStation? {
        if useDefaultValue {
            return try? await suggestedEntities().first
        } else {
            return nil
        }
    }
}
