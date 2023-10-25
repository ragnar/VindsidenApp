//
//  DetailView.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 25/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import WeatherBoxView

struct DetailView: View {
    var station: WidgetData

    @State var isShowingChart: Bool = false

    var body: some View {
        WeatherBoxView(data: station,
                       timeStyle: .relative,
                       useBaro: false
        )
//        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button {
//                    self.isShowingChart.toggle()
//                } label: {
//                    Image(systemName: "chart.xyaxis.line")
//                }
//            }
//        }
//        .sheet(isPresented: $isShowingChart) {
//            StationChartView(station: station)
//        }
    }
}
