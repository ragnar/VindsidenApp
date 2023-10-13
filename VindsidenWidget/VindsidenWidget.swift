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
    @StateObject private var settings: UserObservable = UserObservable()

    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.configuration.station ?? "Unnamed")
            Text(entry.date, style: .relative)
                .font(.caption)
            Chart {
                ForEach(entry.plots, id: \.plotTime) { value in
                    AreaMark(
                        x: .value("Time", value.plotTime, unit: .minute),
                        yStart: .value("Lull", convertedWind(value.windMin)),
                        yEnd: .value("Gust", convertedWind(value.windMax))
                    )
                    .foregroundStyle(by: .value("Series", "Variation"))

                    LineMark(
                        x: .value("Time", value.plotTime, unit: .minute),
                        y: .value("Speed Min", convertedWind(value.windMin))
                    )
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: []))
                    .foregroundStyle(by: .value("Series", "Variation Min"))

                    LineMark(
                        x: .value("Time", value.plotTime, unit: .minute),
                        y: .value("Speed Max", convertedWind(value.windMax))
                    )
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: []))
                    .foregroundStyle(by: .value("Series", "Variation Max"))

                    LineMark(
                        x: .value("Time", value.plotTime, unit: .minute),
                        y: .value("Speed", convertedWind(value.windAvg))
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: []))
                    .foregroundStyle(by: .value("Series", "Average"))
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
            .chartYAxisLabel(settings.windUnit.symbol)
            .chartForegroundStyleScale([
                "Average": Color("AccentColor"),
                "Variation": Color("AccentColor").opacity(0.1),
                "Variation Min": Color("AccentColor").opacity(0.3),
                "Variation Max": Color("AccentColor").opacity(0.3),
            ])
            .chartLegend(.hidden)
        }
    }

    private func showXAxisValue(for index: Int) -> Bool {
        if case .systemSmall = family {
            return index % 2 != 0
        }

        return true
    }

    private func convertedWind(_ base: Double) -> Double {
        let unit = settings.windUnit

        return base.fromUnit(.metersPerSecond).toUnit(unit)
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
