//
//  WatchAppApp.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import UserNotifications
import SwiftData
import OSLog
import VindsidenWatchKit

@main
struct WatchApp_Watch_AppApp: App {
    @State var userSettings: UserObservable

    init() {
        let settings = UserObservable()
        self.userSettings = settings

        WCFetcher.sharedInstance.settings = userSettings
        WCFetcher.sharedInstance.activate()
        UNUserNotificationCenter.current().requestAuthorization(options: [.provisional, .alert, .sound]) { (success, error) in
            if success{
                Logger.debugging.debug("All set")
            } else if let error = error {
                Logger.debugging.debug("\(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(PersistentContainer.shared.container)
                .environment(userSettings)
        }
    }
}
