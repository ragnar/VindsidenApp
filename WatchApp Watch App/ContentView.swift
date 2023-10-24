//
//  ContentView.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import VindsidenWatchKit
import WeatherBoxView

struct ContentView: View {
    @ObservedObject private var data = Resource<WidgetData>()
    @State private var selected: WidgetData?

    var body: some View {
        NavigationSplitView() {
            List(selection: $selected) {
                ForEach($data.value) { station in
                    NavigationLink(value: station.wrappedValue) {
                        ListCell(station: station.wrappedValue)
                    }
                }
            }
            .containerBackground(.accent.gradient, for: .navigation)
            .listStyle(.carousel)
        } detail: {
            TabView(selection: $selected) {
                ForEach($data.value) { station in
                    DetailView(station: station.wrappedValue)
                        .tag(Optional(station.wrappedValue))
                        .containerBackground(.accent.gradient, for: .tabView)
                }
            }
            .tabViewStyle(.verticalPage)
        }
        .task {
            data.isPaused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: WKApplication.didEnterBackgroundNotification)) { _ in
            data.isPaused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: WKApplication.willEnterForegroundNotification)) { _ in
            WCFetcher.sharedInstance.activate()
            data.isPaused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .ReceivedStations)) { _ in
            data.forceFetch()
        }
    }
}

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

struct DetailView: View {
    var station: WidgetData

    var body: some View {
        WeatherBoxView(data: station,
                       timeStyle: .relative,
                       useBaro: false
        )
    }
}

#Preview {
    ContentView()
}
