//
//  VindsidenWidgetEntryView.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Charts
import VindsidenKit

struct VindsidenWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    @Environment(UserObservable.self) var settings

    var entry: Provider.Entry
    var station: IntentStation {
        return entry.configuration.station ?? .templateStation
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text(station.name)
                .foregroundStyle(Color("AccentColor"))
                .widgetAccentable()

            Text(entry.lastDate, style: .relative)
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
                                .rotationEffect(.degrees(Double(entry.plots[value.index].windDir)))
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
        .containerBackground(.fill.tertiary, for: .widget)
        .edgesIgnoringSafeArea([.horizontal, .bottom])
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

