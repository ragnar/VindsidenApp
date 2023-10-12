//
//  VindsidenWidget.swift
//  VindsidenWidget
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Charts
import VindsidenKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let plots: [Plot]
}

struct VindsidenWidgetEntryView : View {
    @Environment(\.widgetFamily) var family

    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.configuration.station ?? "Unnamed")
            Text(entry.date, style: .relative)
                .font(.caption)
            Chart {
                ForEach(entry.plots, id: \.plotTime) { value in
                    AreaMark(
                        x: .value("Tine", value.plotTime, unit: .minute),
                        yStart: .value("Lull", value.windMin),
                        yEnd: .value("Gust", value.windMax)
                    )
                    .foregroundStyle(by: .value("Series", "Variation"))

                    LineMark(
                        x: .value("Time", value.plotTime, unit: .minute),
                        y: .value("Speed", value.windAvg)
                    )

                }
                .interpolationMethod(.catmullRom)

            }
            .chartXAxis {
                AxisMarks(values: entry.plots) { value in
                    if showXAxisValue(for: value.index)  {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Image(systemName: "arrow.down")
                                .rotationEffect(.degrees(entry.plots[value.index].windDir))
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Variation": Color.black.opacity(0.05),
                "Average": Color.blue
            ])
            .chartLegend(.hidden)
        }
    }

    func showXAxisValue(for index: Int) -> Bool {
        if case .systemSmall = family {
            return index % 2 != 0
        }

        return true
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


extension Plot: Plottable {
    typealias PrimitivePlottable = Date

    var primitivePlottable: Date {
        return plotTime
    }
    
    convenience init?(primitivePlottable: Date) {
        nil
    }
}
