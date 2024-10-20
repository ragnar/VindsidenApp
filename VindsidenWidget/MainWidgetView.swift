//
//  MainWidgetView.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI
import WeatherBoxView

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

struct MainWidgetView : View {
    @Environment(\.widgetFamily) var family

    var entry: SinglePlotProvider.Entry

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack {
                    Text(verbatim: entry.widgetData.units.windDirection.symbol)
                        .font(.footnote)
                    Text(verbatim: entry.widgetData.windAverage.formatted(.number.precision(.fractionLength(1))))
                    Text(verbatim: entry.widgetData.units.wind.symbol)
                        .font(.footnote)
                }
            }
        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading) {
                    Text(verbatim: entry.widgetData.name)
                        .font(.headline)
                        .widgetAccentable()

                    Text("\(Image(systemName: "wind")) \(entry.widgetData.units.wind.formatted(value: entry.widgetData.windAverage))")
                    Text(verbatim: "\(entry.widgetData.units.windDirection.symbol), \(entry.widgetData.windAngle.formatted(.number.precision(.fractionLength(0))))°")
                }.frame(maxWidth: .infinity, alignment: .leading)
            }

        case .accessoryInline:
            ViewThatFits {
                Text("\(Image(systemName: "wind")) \(entry.widgetData.units.wind.formatted(value: entry.widgetData.windAverage)) \(entry.widgetData.units.windDirection.symbol)")
            }

        default:
            WeatherBoxView(
                data: entry.widgetData,
                customDateStyle: .relative(presentation: .named),
                useBaro: false
            )
            .edgesIgnoringSafeArea([.horizontal, .bottom])
        }
    }
}
