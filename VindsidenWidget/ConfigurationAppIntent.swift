//
//  ConfigurationAppIntent.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 18/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import AppIntents

struct ConfigurationAppIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Open Station"
    static var description = IntentDescription("Open the application at chosen wind station")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Select station")
    var station: IntentStation?

    @MainActor
    func perform() async throws -> some IntentResult {
#if MAINAPP
        guard
            let delegate = UIApplication.shared.delegate as? RHCAppDelegate,
            let station,
            let url = URL(string: "vindsiden://station/\(station.id)")
        else {
            return .result()
        }

        _ = delegate.openLaunchOptionsURL(url)
#endif

        return .result()
    }
}
