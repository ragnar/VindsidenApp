//
//  ContentView.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 23/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import SwiftData
import WidgetKit
import Charts
import VindsidenWatchKit
import WeatherBoxView
import Units

struct ContentView: View {
    @Environment(UserObservable.self) private var settings
    @State private var data = Resource<WidgetData>()
    @State private var selected: WidgetData?
    @State private var selectedStationName: String?

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
            await fetch()
        }
        .onReceive(NotificationCenter.default.publisher(for: WKApplication.willEnterForegroundNotification)) { _ in
            WCFetcher.sharedInstance.activate()

            Task {
                await fetch()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ReceivedStations)) { _ in
            Task {
                await fetch()
            }
        }
        .onChange(of: $selected.wrappedValue) { _, newValue in
            selectedStationName = newValue?.name
        }
        .onChange(of: settings.lastChanged) {
            Task {
                await data.updateContent()

                guard
                    let name = selectedStationName,
                    let station = findStation(with: name)
                else {
                    return
                }

                selected = station
            }
        }
        .onContinueUserActivity("ConfigurationAppIntent") { activity in
            guard 
                let intent = activity.widgetConfigurationIntent(of: ConfigurationAppIntent.self),
                let station = data.value.first(where: {$0.name == intent.station.name })
            else {
                return
            }

            selectedStationName = station.name
            selected = station
        }
    }
}

extension ContentView {
    func fetch() async {
        await data.reload()

        guard
            let name = selectedStationName,
            let station = findStation(with: name)
        else {
            return
        }

        selected = station
    }

    func findStation(with name: String) -> WidgetData? {
        return data.value.first(where: {$0.name == name })
    }
}

#Preview {
    ContentView()
}
