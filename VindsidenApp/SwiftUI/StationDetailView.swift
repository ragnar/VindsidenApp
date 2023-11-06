//
//  StationDetailView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import OSLog
import VindsidenKit
import WeatherBoxView

struct StationDetailView: View {
    var station: WidgetData

    var body: some View {
        GeometryReader(content: { geometry in
            VStack(alignment: .leading) {
                Text(station.name)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.accent.gradient)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(station.lastUpdated, style: .relative)
                    .padding(.bottom, 16)
                LazyVGrid(columns: [
                    GridItem(.fixed((geometry.size.width - 16) / 2)),
                    GridItem(.fixed((geometry.size.width - 16) / 2)),
                ], alignment: .leading, spacing: 8, content: {
                    InfoView(label: "Wind Speed", value: station.units.wind.formatted(value: station.windSpeed))
                    InfoView(label: "Average", value: station.units.wind.formatted(value: station.windAverage))
                    InfoView(label: "Wind Gust", value: station.units.wind.formatted(value: station.windGust))
                    InfoView(label: "Wind Beaufort", value: "1")
                    InfoView(label: "Wind Direction", value: "\(station.windAngle.formatted(.number.precision(.fractionLength(0))))° (\(station.units.windDirection.symbol))")
                    InfoView(label: "Temp Air", value: station.units.temp.formatted(value: station.temp))
                })
                Spacer()
                SwiftUIPlotGraph(station: station)
                    .frame(minHeight: 200, maxHeight: 240)
            }
        })
    }
}

#Preview {
    StationDetailView(station: WidgetData(customIdentifier: nil, name: nil))
}
