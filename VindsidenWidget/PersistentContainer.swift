//
//  PersistentContainer.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 12/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import VindsidenKit

struct PersistentContainer {
    @MainActor
    static var container: ModelContainer {
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.ApplicationGroups.primary) else {
            fatalError("Shared file container could not be created.")
        }

        let url = appGroupContainer.appendingPathComponent(AppConfig.CoreData.sqliteName)
        let schema = Schema([Station.self, Plot.self])
        let configuration = ModelConfiguration(url: url)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }
}
