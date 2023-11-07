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

fileprivate let maxPlotCount = 35

extension Array where Element: VindsidenKit.Plot {
    var latest: Self {
        if isEmpty {
            return []
        }

        return Array(self[..<Swift.min(count, maxPlotCount)])
    }
}

struct SwiftUIPlotGraph: View {
    @Environment(UserObservable.self) private var settings

    @Query
    var plots: [VindsidenKit.Plot]
    let station: WidgetData

    init(station: WidgetData) {
        self.station = station

        let name = station.name
        let interval =  Int(-1 * AppConfig.Global.plotHistory)
        let date = Calendar.current.date(byAdding: .hour, value: interval, to: Date())!
        var fetchDescriptor = FetchDescriptor<VindsidenKit.Plot>(predicate: #Predicate<VindsidenKit.Plot> { $0.station?.stationName == name && $0.plotTime > date },
                                                                 sortBy: [SortDescriptor<VindsidenKit.Plot>(\.dataId, order: .reverse) ])
        fetchDescriptor.fetchLimit = maxPlotCount

        self._plots = Query(fetchDescriptor)
    }

    var body: some View {
        Chart {
            ForEach(plots.latest, id: \.plotTime) { value in
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
            AxisMarks(values: plots.latest) { value in
                AxisGridLine()
                AxisTick()
                
                if let windDir = plots[value.as(Date.self)]?.windDir {
                    AxisValueLabel {
                        Image(systemName: "arrow.down")
                            .rotationEffect(.degrees(windDir))
                    }
                }
            }
        }
        .chartYAxisLabel(settings.windUnit.symbol)
        .chartForegroundStyleScale([
            "Average": Color.accentColor,
            "Variation": Color.accentColor.opacity(0.1),
            "Variation Min": Color.accentColor.opacity(0.4),
            "Variation Max": Color.accentColor.opacity(0.4),
        ])
        .chartLegend(.hidden)
    }

    func convertedWind(_ base: Double?) -> Double {
        let value = base ?? -999
        let unit = settings.windUnit

        return value.fromUnit(.metersPerSecond).toUnit(unit)
    }
}
