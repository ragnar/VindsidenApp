//
//  SwiftUIPlotGraph.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import Charts
import SwiftData
import Units

struct SwiftUIPlotGraph: View {
    @EnvironmentObject private var settings: UserObservable
    @Environment(\.managedObjectContext) private var viewContext

    var stationId: Int

    @FetchRequest private var plots: FetchedResults<CDPlot>

    init(stationId: Int) {
        let gregorian = NSCalendar(identifier: .gregorian)!
        let inDate = Date().addingTimeInterval(-1*(5-1)*3600)
        let inputComponents = gregorian.components([.year, .month, .day, .hour], from: inDate)
        let outDate = gregorian.date(from: inputComponents) ?? Date()

        self.stationId = stationId
        self._plots = FetchRequest<CDPlot>(sortDescriptors: [SortDescriptor(\.plotTime)],
                                           predicate: NSPredicate(format: "station.stationId == %d AND plotTime >= %@", stationId, outDate as CVarArg)
        )
    }

    var body: some View {
        Chart {
            ForEach(plots) { value in
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
            AxisMarks(values: Array(plots)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Image(systemName: "arrow.down")
                        .rotationEffect(.degrees(plots[value.index].windDir!.doubleValue))
                }
            }
        }
        .chartYAxisLabel(settings.windUnit.symbol)
        .chartForegroundStyleScale([
            "Average": Color("AccentColor"),
            "Variation": Color("AccentColor").opacity(0.1),
            "Variation Min": Color("AccentColor").opacity(0.2),
            "Variation Max": Color("AccentColor").opacity(0.2),
        ])
        .chartLegend(.hidden)
    }

    func convertedWind(_ base: NSNumber?) -> Double {
        let value = base?.doubleValue ?? -1
        let unit = settings.windUnit

        return value.fromUnit(.metersPerSecond).toUnit(unit)
    }
}
