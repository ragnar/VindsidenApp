//
//  VindsidenWidgetBundle.swift
//  VindsidenWidget
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct VindsidenWidgetBundle: WidgetBundle {
    var body: some Widget {
        MainWidget()
        VindsidenWidget()
    }
}

struct VindsidenWidget: Widget {
    let kind: String = "VindsidenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            VindsidenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct MainWidget: Widget {
    let kind: String = "MainWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: SinglePlotProvider()
        ) { entry in
            MainWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather station")
        .description("Display your favorite spot on your home screen")
#if os(watchOS)
        .supportedFamilies([
            .accessoryCircular,
                            .accessoryRectangular,
                            .accessoryInline,
        ])
#else
        .supportedFamilies([.accessoryCircular,
                            .accessoryRectangular,
                            .accessoryInline,
                            .systemSmall,
        ])
#endif
    }
}

