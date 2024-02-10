//
//  WidgetData.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import WeatherBoxView
import Units

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

extension WidgetData {
    static func loadData(for stationId: Int, stationName: String) async throws -> WidgetData? {
        try await WindManager.shared.fetch(station: (stationId, stationName))

        let modelContainer: ModelContainer = await PersistentContainer.shared.container
        let actor = PlotModelActor(modelContainer: modelContainer)

        return try await actor.widgetData(for: stationId, stationName: stationName)
    }
}
