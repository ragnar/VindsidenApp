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
    @Environment(UserObservable.self) private var settings
    @Environment(NavigationModel.self) private var navigationModel
    
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var activeSheet: Sheet? = nil
    @State private var restored: Bool = false
    @State private var gaugeMaxValue: Double = 20
    @State private var data = Resource<WidgetData>()
    @State private var selectedStationId: String?
    @State private var selected: WidgetData? 
    @State private var stationInfoChanged: Bool = false

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
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Text(data.updateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

            }
        } detail: {
            TabView(selection: $selected) {
                ForEach($data.value) { station in
                    StationDetailView(station: station.wrappedValue)
                        .environment(settings)
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
                        settings.selectedStationId = nil
                        selectedStationId = nil
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
                SettingsView()

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
        .currentDeviceNavigationSplitViewStyle()
        .onChange(of: data.value, handleDataValueChange)
        .onChange(of: $selected.wrappedValue, handleSelectedChange)
        .onChange(of: navigationModel.pendingSelectedStationId, handleNavigationStationValueChange)
        .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlight)
        .onContinueUserActivity("ConfigurationAppIntent", perform: handleIntent)
        .onOpenURL(perform: handleOpenURL)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: handleNotificationForeground)
        .refreshable(action: handleRefreshable)
        .task(handleRestore)
    }

    @MainActor
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
        guard let intent = userActivity.widgetConfigurationIntent(of: ConfigurationAppIntent.self) else {
            return
        }

        setSelected(overrideIdentifier: "\(intent.station.id)")
    }

    func handleOpenURL(url: URL) {
        guard let identifier = url.pathComponents.last else {
            return
        }

        setSelected(overrideIdentifier: identifier)
    }

    func handleDataValueChange(_ oldValue: [WidgetData], _ newValue: [WidgetData]) {
        stationInfoChanged = true
        Logger.debugging.debug("Station info changed.")
        setSelected()
        updateGaugeMaxValue()
    }

    func handleSelectedChange(_ oldValue: WidgetData?, _ newValue: WidgetData?) {
        Logger.debugging.debug("Station change: old: \(oldValue?.name ?? "not set"), new: \(newValue?.name ?? "not set")")

        if oldValue == nil {
            selectedStationId = newValue?.customIdentifier
            settings.selectedStationId = newValue?.customIdentifier
            return
        }

        if stationInfoChanged {
            setSelected()
            Logger.debugging.debug("Ignore station change")
            stationInfoChanged = false
            return
        }

        Logger.debugging.debug("Selected updated")
        selectedStationId = newValue?.customIdentifier
        settings.selectedStationId = newValue?.customIdentifier
    }

    @MainActor 
    func handleNavigationStationValueChange(_ oldValue: Int?, _ newValue: Int?) {
        guard let newValue else {
            return
        }

        navigationModel.pendingSelectedStationId = nil
        setSelected(overrideIdentifier: "\(newValue)")
    }

    func handleNotificationForeground(_ output: NotificationCenter.Publisher.Output) {
        Task {
            try? await Task.sleep(nanoseconds:500)
            await fetch()
        }
    }

    @Sendable
    func handleRefreshable() async {
        await fetch()
    }

    @Sendable
    func handleRestore() async {
        if restored {
            return
        }

        restored = true

        await data.updateContent()

        Logger.debugging.debug("name: restore: \(settings.selectedStationId ?? "not set")")

        if let stationId = settings.selectedStationId {
            setSelected(overrideIdentifier: stationId)
        }

        if await WindManager.shared.updateStations() {
            Logger.debugging.debug("Got new stations.")
            await data.updateContent()
        }

        await fetch()
    }
}

extension ContentView {
    func fetch() async {
        try? await data.reload()
        setSelected()
    }

    func updateGaugeMaxValue() {
        let maxValue = 20.toUnit(settings.windUnit)
        let maxAverage = data.value.max(by: { $0.windAverage < $1.windAverage})?.windAverage ?? 19.0
        $gaugeMaxValue.wrappedValue = (max(maxValue, maxAverage) / 10).rounded(.up)*10
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
