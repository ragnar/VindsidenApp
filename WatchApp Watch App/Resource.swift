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
import VindsidenWatchKit
import WeatherBoxView
import Units

public typealias ResourceProtocol = Decodable & Identifiable
typealias RefreshMethodHandler = () -> Void

final public class Resource<T: ResourceProtocol>: ObservableObject {
    @Published public var value: [WidgetData]

    public var isPaused: Bool = true {
        didSet {
            if isPaused == false {
                forceFetch()
            }
        }
    }

    let fetcher = PlotFetcher()

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
    private func reload() async {
        await WindManager.sharedManager.fetch()
        await updateContent()
    }

    @MainActor
    private func updateContent() async {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

        let modelContainer = PersistentContainer.shared.container
        
        guard let stations = try? modelContainer.mainContext.fetch(fetchDescriptor) else {
            return
        }

        var widgetDatas = [WidgetData]()

        stations.forEach { widgetDatas.append($0.widgetData()) }

        self.value = widgetDatas
    }
}
