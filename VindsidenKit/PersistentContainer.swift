//
//  PersistentContainer.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 12/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import OSLog

public struct PersistentContainer {
    public static let shared = PersistentContainer()

    private init() {
        Logger.debugging.error("Model container created")
    }

    @MainActor
    public var container: ModelContainer {
        let schema = Schema([Station.self, Plot.self])
        let configuration = ModelConfiguration("Vindsiden", groupContainer: .identifier(AppConfig.ApplicationGroups.primary))

        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            return container
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }
}
