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

@MainActor
public struct PersistentContainer: Sendable {
    public static let shared = PersistentContainer()

    private static var privateContainer: ModelContainer?

    private init() {
        Logger.debugging.error("Model container created")

    }

    public var container: ModelContainer {
        if let container = Self.privateContainer {
            return container
        }

        let schema = Schema([Station.self, Plot.self])
        let configuration = ModelConfiguration("Vindsiden", groupContainer: .identifier(AppConfig.ApplicationGroups.primary))

        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            container.mainContext.autosaveEnabled = true
            Self.privateContainer = container

            return container
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }
}
