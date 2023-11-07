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
    @State private var selectedStationId: String?
    @State private var stationInfoChanged: Bool = false

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
            await data.updateContent()
            await fetch()
        }
        .onReceive(NotificationCenter.default.publisher(for: WKApplication.willEnterForegroundNotification), perform: handleNotification)
        .onReceive(NotificationCenter.default.publisher(for: .ReceivedStations), perform: handleNotification)
        .onChange(of: data.value, handleDataValueChange)
        .onChange(of: $selected.wrappedValue) { oldValue, newValue in
            if oldValue == nil {
                selectedStationId = newValue?.customIdentifier
                return
            }

            if stationInfoChanged {
                setSelected()
                stationInfoChanged = false
                return
            }

            selectedStationId = newValue?.customIdentifier
        }
        .onChange(of: settings.lastChanged) {
            Task {
                await data.updateContent()
                setSelected()
            }
        }
        .onContinueUserActivity("ConfigurationAppIntent") { activity in
            guard let intent = activity.widgetConfigurationIntent(of: ConfigurationAppIntent.self) else {
                return
            }

            setSelected(overrideIdentifier: "\(intent.station.id)")
        }
    }
}

extension ContentView {
    func handleNotification(_ output: NotificationCenter.Publisher.Output) {
        WCFetcher.sharedInstance.activate()

        Task {
            await data.updateContent()
            await fetch()
        }
    }

    func handleDataValueChange(_ oldValue: [WidgetData], _ newValue: [WidgetData]) {
        stationInfoChanged = true
        setSelected()
    }

    func fetch() async {
        try? await data.reload()
    }

    func findStation(withIdentifier identifier: String) -> WidgetData? {
        return data.value.first(where: {$0.customIdentifier == identifier })
    }

    func setSelected(overrideIdentifier: String? = nil) {
        guard
            let stationId = overrideIdentifier ?? selectedStationId,
            let station = findStation(withIdentifier: stationId)
        else {
            return
        }

        selected = station
    }
}

#Preview {
    ContentView()
}
