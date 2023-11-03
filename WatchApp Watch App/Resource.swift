//
//  Resource.swift
//  WatchApp Watch App
//
//  Created by Ragnar Henriksen on 24/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import OSLog
import WeatherBoxView
import Units

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

public typealias ResourceProtocol = Decodable & Identifiable
typealias RefreshMethodHandler = () -> Void

@Observable
final public class Resource<T: ResourceProtocol> {
    let fetcher = PlotFetcher()

    public var value: [WidgetData]

    public init() {
        self.value = []
        Task {
            await updateContent()
        }
    }

    public func forceFetch() {
        Task {
            await reload()
        }
    }

    @MainActor
    func reload() async {
        try? await WindManager.shared.fetch()
        await updateContent()
    }

    @MainActor
    func updateContent() async {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

        let modelContainer = PersistentContainer.shared.container
        
        guard let stations = try? modelContainer.mainContext.fetch(fetchDescriptor) else {
            return
        }

        var widgetDatas = [WidgetData]()

        stations.forEach { widgetDatas.append($0.widgetData()) }

        self.value = widgetDatas

        Logger.debugging.debug("Reloaded \(widgetDatas.count) stations.")
    }
}
