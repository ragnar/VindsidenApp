//
//  StationDetailView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import OSLog
import VindsidenKit
import WeatherBoxView

fileprivate let maxPlotCount = 35

extension Array where Element: VindsidenKit.Plot {
    var latest: Self {
        if isEmpty {
            return []
        }

        return Array(self[..<Swift.min(count, maxPlotCount)])
    }
}

struct StationDetailView: View {
    var station: WidgetData

    @Query
    var plots: [VindsidenKit.Plot]

    init(station: WidgetData) {
        self.station = station

        let identifier = Int(station.customIdentifier ?? "-1") ?? -1
        let interval =  Int(-1 * AppConfig.Global.plotHistory)
        let date = Calendar.current.date(byAdding: .hour, value: interval, to: Date())!
        var fetchDescriptor = FetchDescriptor<VindsidenKit.Plot>(predicate: #Predicate<VindsidenKit.Plot> { $0.stationId == identifier && $0.plotTime > date },
                                                                 sortBy: [SortDescriptor<VindsidenKit.Plot>(\.dataId, order: .reverse) ])
        fetchDescriptor.fetchLimit = maxPlotCount

        self._plots = Query(fetchDescriptor)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(station.name)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.accent.gradient)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(plots.first?.plotTime ?? station.lastUpdated, style: .relative)
                .padding(.bottom, 16)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], alignment: .leading, spacing: 8, content: {
                if let plot = plots.first {
                    InfoView(label: "Wind", value: station.units.wind.formatted(value: plot.windMin.fromUnit(.metersPerSecond).toUnit(station.units.wind)))
                    InfoView(label: "Wind Lull", value: station.units.wind.formatted(value: plot.windAvg.fromUnit(.metersPerSecond).toUnit(station.units.wind)))
                    InfoView(label: "Wind Gust", value: station.units.wind.formatted(value: plot.windMax.fromUnit(.metersPerSecond).toUnit(station.units.wind)))
                    InfoView(label: "Wind Beaufort", value: plot.windAvg.fromUnit(.metersPerSecond).toUnit(.knots).toUnit(.beaufort).formatted())
                    InfoView(label: "Wind Direction", value: "\(plot.windDir.formatted(.number.precision(.fractionLength(0))))° (\(station.units.windDirection.symbol))")
                    InfoView(label: "Temp Air", value: station.units.temp.formatted(value: Optional(plot.tempAir)))
                } else {
                    InfoView(label: "Wind", value: "-.- \(station.units.wind.symbol)")
                    InfoView(label: "Wind Lull", value: "-.- \(station.units.wind.symbol)")
                    InfoView(label: "Wind Gust", value: "-.- \(station.units.wind.symbol)")
                    InfoView(label: "Wind Beaufort", value: "-")
                    InfoView(label: "Wind Direction", value: "-")
                    InfoView(label: "Temp Air", value: "-.- \(station.units.temp.symbol)")
                }
            })

            Spacer()

            if plots.isEmpty {
                ContentUnavailableView {
                    Label("Graph",
                          systemImage: "chart.xyaxis.line")
                } description: {
                    Text("Not enough data points to show graph.")
                }
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 240)
            } else {
                SwiftUIPlotGraph(station: station, plots: plots.latest.map { SendablePlot(from: $0)})
                    .frame(minHeight: 200, maxHeight: 240)
            }
        }
    }
}

#Preview {
    StationDetailView(station: WidgetData(customIdentifier: nil, name: nil))
}
