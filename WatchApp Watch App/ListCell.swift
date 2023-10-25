//
//  ListCell.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 25/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import WeatherBoxView

struct ListCell: View {
    var station: WidgetData

    var body: some View {
        HStack {
            Image(systemName: "arrow.down")
                .rotationEffect(.degrees(station.windAngle))

            VStack(alignment: .leading) {
                Text(verbatim: station.name)
                Text(station.lastUpdated, style: .relative)
                    .font(.footnote)
            }
        }
    }
}
