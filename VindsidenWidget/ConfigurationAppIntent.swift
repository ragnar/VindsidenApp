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
    static let title: LocalizedStringResource = "Open Station"
    static let description = IntentDescription("Open the application at chosen wind station")

    @Parameter(title: "Select station")
    var station: IntentStation?
}
