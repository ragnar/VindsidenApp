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
    static var container: ModelContainer {
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.ApplicationGroups.primary) else {
            fatalError("Shared file container could not be created.")
        }

        let url = appGroupContainer.appendingPathComponent(AppConfig.CoreData.sqliteName)

        do {
            return try ModelContainer(for: Station.self, Plot.self, configurations: ModelConfiguration(url: url))
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }
}
