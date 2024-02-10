//
//  VindsidenWidgetBundle.swift
//  VindsidenWidget
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

@main
struct VindsidenWidgetBundle: WidgetBundle {
    var body: some Widget {
        MainWidget()
#if os(iOS)
        VindsidenWidget()
#endif
    }
}

#if os(iOS)
struct VindsidenWidget: Widget {
    @State private var settings: UserObservable

    let kind: String = "VindsidenWidget"

    init() {
        settings = UserObservable()
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            VindsidenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .environment(settings)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
#endif

struct MainWidget: Widget {
    let kind: String = "MainWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: SinglePlotProvider()
        ) { entry in
            MainWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)

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
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
        ])
#endif
    }
}

