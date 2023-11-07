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

    @State private var rawSelectedDate: Date?

    private var selectedDate: Date? {
        guard let rawSelectedDate else {
            return nil
        }

        return plots.first(where: { $0.plotTime <= rawSelectedDate})?.plotTime
    }

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

                if let selectedDate {
                    RuleMark(
                        x: .value("Selected", selectedDate)
                    )
                    .offset(yStart: -10)
                    .zIndex(-1)
                    .annotation(
                        position: .top, spacing: 0,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        valueSelectionPopover
                    }
                }
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
        .chartXSelection(value: $rawSelectedDate)
    }

    @ViewBuilder
    var valueSelectionPopover: some View {
        if let selectedDate, let plot = plots[selectedDate] {
            VStack(alignment: .leading) {
                Text("Wind at \(plot.plotTime, format: .dateTime.hour().minute())")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .center, spacing: 0) {
                        Text("\(plot.windMax, format: .number.precision(.fractionLength(1)))")
                            .font(.title2.bold())
                            .foregroundStyle(.accent.gradient)

                        Text("Gust")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .center, spacing: 0) {
                        Text("\(plot.windAvg, format: .number.precision(.fractionLength(1)))")
                            .font(.title2.bold())
                            .foregroundStyle(.accent.gradient)
                    }

                    VStack(alignment: .center, spacing: 0) {
                        Text("\(plot.windMin, format: .number.precision(.fractionLength(1)))")
                            .font(.title2.bold())
                            .foregroundStyle(.accent.gradient)

                        Text("Lull")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(.thinMaterial)
            }
        } else {
            EmptyView()
        }
    }
    func convertedWind(_ base: Double?) -> Double {
        let value = base ?? -999
        let unit = settings.windUnit

        return value.fromUnit(.metersPerSecond).toUnit(unit)
    }
}
