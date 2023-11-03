//
//  SwiftUIPlotGraph.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import Charts
import VindsidenKit
import WeatherBoxView
import Units

struct SwiftUIPlotGraph: View {
    @Environment(UserObservable.self) private var settings

    @Query
    var plots: [VindsidenKit.Plot]
    let station: WidgetData
    let maxPlotCount = 35

    init(station: WidgetData) {
        let name = station.name
        let interval =  Int(-1 * AppConfig.Global.plotHistory)
        let date = Calendar.current.date(byAdding: .hour, value: interval, to: Date())!

        self.station = station
        self._plots = Query(filter: #Predicate<VindsidenKit.Plot> { $0.station?.stationName == name && $0.plotTime > date },
                            sort: \.dataId,
                            order: .reverse
        )
    }

    var body: some View {
        Chart {
            ForEach(plots[..<min(plots.count, maxPlotCount)], id: \.plotTime) { value in
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
            AxisMarks(values: Array(plots[..<min(plots.count, maxPlotCount)])) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Image(systemName: "arrow.down")
                        .rotationEffect(.degrees(Double(plots[value.index].windDir)))
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

    func convertedWind(_ base: Double?) -> Double {
        let value = base ?? -999
        let unit = settings.windUnit

        return value.fromUnit(.metersPerSecond).toUnit(unit)
    }
}
