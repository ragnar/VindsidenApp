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
import WidgetKit

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
        .onContinueUserActivity("ConfigurationAppIntent") { activity in
            guard 
                let intent = activity.widgetConfigurationIntent(of: ConfigurationAppIntent.self),
                let station = data.value.first(where: {$0.name == intent.station.name })
            else {
                return
            }

            selected = station
        }
    }
}

#Preview {
    ContentView()
}
