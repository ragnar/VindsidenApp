//
//  ContentView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import WidgetKit
import CoreSpotlight
import OSLog
import VindsidenKit
import WeatherBoxView

struct ContentView: View {
    enum Sheet: Hashable, Identifiable {
        case settings
        case selectedInfo
        case info(String)
        case image(String, URL)

        var id: Int {
            return self.hashValue
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var settings: UserObservable
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var selected: WidgetData?
    @State private var activeSheet: Sheet? = nil
    @State private var restored: Bool = false
    @State private var gaugeMaxValue: Double = 20
    @State private var pendingSelection: String?

    @ObservedObject private var data = Resource<WidgetData>()

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            List(selection: $selected) {
                ForEach($data.value) { station in
                    NavigationLink(value: station.wrappedValue) {
                        ListCell(station: station.wrappedValue, maxValue: $gaugeMaxValue.wrappedValue)
                            .contextMenu {
                                contextMenuBuilder(name: station.wrappedValue.name)
                            }
                    }
                }
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationTitle("Stations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        } detail: {
            TabView(selection: $selected) {
                ForEach($data.value) { station in
                    StationDetailView(station: station.wrappedValue)
                        .environmentObject(settings)
                        .tag(Optional(station.wrappedValue))
                        .padding([.leading, .trailing])
                        .navigationBarBackButtonHidden(true)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        activeSheet = .selectedInfo
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    Spacer()
                    PageControl(selection: $selected, listOfItems: $data.value)
                        .frame(maxWidth: .infinity)
                    Spacer()
                    Button {
                        selected = nil
                    } label: {
                        Image(systemName: "list.bullet")

                    }
                    .opacity(UIDevice.current.userInterfaceIdiom == .pad ? 0 : 1)
                }
            }
        }
        .sheet(item: $activeSheet, onDismiss: {
            Task {
                await data.updateContent()
                updateGaugeMaxValue()
                Connectivity.shared.updateApplicationContextToWatch()
                await fetch()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }, content: { item in
            switch item {
            case .settings:
                SettingsView(dismissAction: { })

            case .selectedInfo:
                if let selected {
                    StationDetailsView(stationName: selected.name)
                } else {
                    EmptyView()
                }

            case .info(let name):
                StationDetailsView(stationName: name)

            case .image(let title, let url):
                NavigationView {
                    PhotoView(title: title, imageUrl: url)
                }
            }
        })
        .onChange(of: data.value, handleDataValueChange)
        .onChange(of: $selected.wrappedValue, handleSelectedChange)
        .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlight)
        .onContinueUserActivity("ConfigurationAppIntent", perform: handleIntent)
        .onOpenURL(perform: handleOpenURL)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: handleNotificationBackground)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: handleNotificationForeground)
        .refreshable(action: handleRefreshable)
        .task(handleRestore)
    }

    @ViewBuilder
    func contextMenuBuilder(name: String) -> some View {
        Button {
            activeSheet = .info(name)
        } label: {
            Label("Details", systemImage: "info.circle")
        }

        if let url = Station.webcamurl(stationName: name, in: modelContext) {
            Button {
                activeSheet = .image(name, url)
            } label: {
                Label("Show image", systemImage: "photo.circle")
            }
        }

        Button {
            Task {
                Station.hide(stationName: name, in: modelContext)
                await data.updateContent()
            }
        } label: {
            Label("Hide", systemImage: "eye.slash.circle")
        }
    }
}

extension ContentView {
    func handleSpotlight(userActivity: NSUserActivity) {
        guard
            let userInfo = userActivity.userInfo,
            let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
            let url = URL(string: urlString)
        else {
            return
        }

        openURL(url)
    }

    func handleIntent(userActivity: NSUserActivity) {
        guard
            let intent = userActivity.widgetConfigurationIntent(of: ConfigurationAppIntent.self),
            let station = findStation(with: intent.station.name)
        else {
            return
        }

        pendingSelection = intent.station.name
        selected = station
    }

    func handleOpenURL(url: URL) {
        guard
            let identifier = url.pathComponents.last,
            let station = findStation(withIdentifier: identifier)
        else {
            return
        }

        pendingSelection = station.name
        selected = station
    }

    func handleDataValueChange(_ oldValue: any Equatable, _ newValue: any Equatable) {
        updateGaugeMaxValue()
    }

    func handleSelectedChange(_ oldValue: any Equatable, _ newValue: any Equatable) {
        settings.selectedStationName = selected?.name
    }

    func handleNotificationBackground(_ output: NotificationCenter.Publisher.Output) {
        data.isPaused = true
    }

    func handleNotificationForeground(_ output: NotificationCenter.Publisher.Output) {
        data.isPaused = false

        Task {
            await fetch()
        }
    }

    @Sendable
    func handleRefreshable() async {
        await fetch()
    }

    @Sendable
    func handleRestore() async {
        if restored == false {
            restored = true

            let inserted = await WindManager.shared.updateStations()
            Logger.debugging.debug("Got new stations: \(inserted)")

            if inserted {
                await data.updateContent()
            }

            guard
                let name = settings.selectedStationName,
                let station = data.value.first(where: {$0.name == name })
            else {
                await fetch()
                return
            }

            pendingSelection = name
            selected = station

            await fetch()
        }
    }
}

extension ContentView {
    func fetch() async {
        let name = selected?.name

        await data.reload()

        defer {
            pendingSelection = nil
        }

        guard
            let name = pendingSelection ?? name,
            let station = findStation(with: name)
        else {
            return
        }

        selected = station
    }

    func updateGaugeMaxValue() {
        let maxValue = 20.toUnit(settings.windUnit)
        let maxAverage = data.value.max(by: { $0.windAverage < $1.windAverage})?.windAverage ?? 19.0
        $gaugeMaxValue.wrappedValue = (max(maxValue, maxAverage) / 10).rounded(.up)*10
    }

    func findStation(with name: String) -> WidgetData? {
        return data.value.first(where: {$0.name == name })
    }

    func findStation(withIdentifier identifier: String) -> WidgetData? {
        return data.value.first(where: {$0.customIdentifier == identifier })
    }
}
