//
//  VindsidenApp.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import AppIntents
import SwiftData
import VindsidenKit

@main
struct VindsidenApp: App {
    @State var userSettings: UserObservable
    @State var navigationModel: NavigationModel

    var session = Connectivity.shared

    init() {
        let userSettings = UserObservable()
        self.userSettings = userSettings

        let navigationModel = NavigationModel(pendingSelectedStationId: nil)
        self.navigationModel = navigationModel

        AppDependencyManager.shared.add(dependency: navigationModel)

        session.settings = userSettings
        session.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(PersistentContainer.shared.container)
                .environment(userSettings)
                .environment(navigationModel)
        }
    }
}
