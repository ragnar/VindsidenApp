//
//  StationChartView.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 25/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import Charts
import VindsidenWatchKit
import WeatherBoxView

struct StationChartView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @Query
    var plots: [VindsidenWatchKit.Plot]
    let station: WidgetData

    init(station: WidgetData) {
        self.station = station

        let name = station.name
        let date = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!

        self._plots = Query(filter: #Predicate<VindsidenWatchKit.Plot> { $0.station?.stationName == name && $0.plotTime > date },
                            sort: \.dataId)

        print(plots)
    }

    var body: some View {
        Chart {
            ForEach(plots[..<20], id: \.plotTime) { value in
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
            AxisMarks(values: Array(plots[..<20])) { value in
                if showXAxisValue(for: value.index)  {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Image(systemName: "arrow.down")
                            .rotationEffect(.degrees(Double(plots[value.index].windDir)))
                    }
                }
            }
        }
        .chartYAxisLabel(station.units.wind.symbol)
        .chartForegroundStyleScale([
            "Average": Color("AccentColor"),
            "Variation": Color("AccentColor").opacity(0.1),
            "Variation Min": Color("AccentColor").opacity(0.3),
            "Variation Max": Color("AccentColor").opacity(0.3),
        ])
        .chartLegend(.hidden)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }

    private func showXAxisValue(for index: Int) -> Bool {
        return index % 2 == 0
    }

    private func convertedWind(_ base: Float) -> Double {
        return Double(base).fromUnit(.metersPerSecond).toUnit(station.units.wind)
    }
}
