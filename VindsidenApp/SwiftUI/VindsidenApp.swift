//
//  VindsidenApp.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import VindsidenKit

@main
struct VindsidenApp: App {
    var userSettings = UserObservable()
    var session = Connectivity.shared

    init() {
        session.settings = userSettings
        session.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(PersistentContainer.shared.container)
                .environmentObject(userSettings)
        }
    }
}
