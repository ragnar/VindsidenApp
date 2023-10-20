//
//  SwiftUIPlotGraph.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import Charts
import Units

struct SwiftUIPlotGraph: View {
    @EnvironmentObject private var settings: UserObservable
    @ObservedObject var observer: PlotObservable

    var body: some View {
        Chart {
            ForEach(observer.plots) { value in
                AreaMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    yStart: .value("Lull", convertedWind(value.windMin)),
                    yEnd: .value("Gust", convertedWind(value.windMax))
                )
                .foregroundStyle(by: .value("Series", "Variation"))

                LineMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    y: .value("Speed Min", convertedWind(value.windMin))
                )
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: []))
                .foregroundStyle(by: .value("Series", "Variation Min"))

                LineMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    y: .value("Speed Max", convertedWind(value.windMax))
                )
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: []))
                .foregroundStyle(by: .value("Series", "Variation Max"))

                LineMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    y: .value("Speed", convertedWind(value.windAvg))
                )
                .lineStyle(StrokeStyle(lineWidth: 1, dash: []))
                .foregroundStyle(by: .value("Series", "Average"))
            }
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: Array(observer.plots)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Image(systemName: "arrow.down")
                        .rotationEffect(.degrees(observer.plots[value.index].windDir!.doubleValue))
                }
            }
        }
        .chartYAxisLabel(settings.windUnit.symbol)
        .chartForegroundStyleScale([
            "Average": Color.accentColor,
            "Variation": Color.accentColor.opacity(0.1),
            "Variation Min": Color.accentColor.opacity(0.2),
            "Variation Max": Color.accentColor.opacity(0.2),
        ])
        .chartLegend(.hidden)
    }

    func convertedWind(_ base: NSNumber?) -> Double {
        let value = base?.doubleValue ?? -1
        let unit = settings.windUnit

        return value.fromUnit(.metersPerSecond).toUnit(unit)
    }
}
