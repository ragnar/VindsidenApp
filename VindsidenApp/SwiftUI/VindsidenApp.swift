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
import BackgroundTasks
import OSLog
import WidgetKit
import VindsidenKit

@main
struct VindsidenApp: App {
    private static let bgAppIdentifier = "VindsidenRefreshTask"

    @Environment(\.scenePhase) private var scenePhase

    @State var userSettings: UserObservable = UserObservable()
    @State var navigationModel: NavigationModel?

    var session = Connectivity.shared

    init() {
        let navigationModel = NavigationModel(pendingSelectedStationId: nil)
        self._navigationModel = .init(initialValue: navigationModel)

        AppDependencyManager.shared.add(dependency: navigationModel)
        AppShortcuts.updateAppShortcutParameters()

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
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                scheduleAppRefresh()
            default:
                break
            }
        }
        .backgroundTask(.appRefresh(Self.bgAppIdentifier)) {
            Logger.debugging.debug("Performing app refresh.")
            scheduleAppRefresh()

            do {
                for try await name in await WindManager.shared.streamFetch() {
                    Logger.resource.debug("Finished with: \(name)")
                }

                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                Logger.debugging.error("Performing app refresh failed: \(error)")
            }

            Logger.debugging.debug("Finished performing app refresh.")
        }
    }

    private func scheduleAppRefresh() {
        Logger.debugging.debug("Scheduling app refresh.")

        let request = BGAppRefreshTaskRequest(identifier: Self.bgAppIdentifier)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.debugging.error("Submitting background task failed: \(error)")
        }
    }
}
