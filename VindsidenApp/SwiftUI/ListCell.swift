//
//  ListCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 30/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import WeatherBoxView

struct ListCell: View {
    var station: WidgetData
    var maxValue: Double

    let gradient = Gradient(colors: [.green, .orange, .red])

    var body: some View {
        HStack {
            Gauge(value: station.windAverage, in: 0...maxValue) {

            } currentValueLabel: {
                Text(station.windAverage, format: .number.precision(.fractionLength(1)))
            } minimumValueLabel: {
                Text(verbatim: "0")
                    .foregroundColor(.green)
            } maximumValueLabel: {
                Text(verbatim: "\(Int(maxValue))")
                    .foregroundColor(.red)

            }
            .gaugeStyle(.accessoryCircular)
            .tint(gradient)

            Image(systemName: "arrow.down")
                .rotationEffect(.degrees(station.windAngle))
                .font(.title2)

            VStack(alignment: .leading) {
                Text(verbatim: station.name)
                    .font(.headline)
                Text(station.lastUpdated, style: .relative)
                    .font(.footnote)
            }
        }
    }
}

#Preview {
    ListCell(station: WidgetData(), maxValue: 20)
}
