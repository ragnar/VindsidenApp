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
    public var value: [WidgetData]
    public var updateText: LocalizedStringResource

    @ObservationIgnored private var refreshTask: Task<Void, Error>?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastUpdated: Date?
    @ObservationIgnored private var refreshing: Bool = false

    @ObservationIgnored private lazy var formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.formattingContext = .middleOfSentence
        formatter.dateTimeStyle = .named

        return formatter
    }()

    public init() {
        self.value = []
        self.updateText = "Checking for updates..."
    }

    public func forceFetch() {
        Task {
            try? await reload()
        }
    }

    @MainActor
    func reload() async throws {
        Logger.resource.debug("Resource started refreshing")

        if let refreshTask {
            Logger.resource.debug("Resource already refreshing")
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> Void in
            defer {
                refreshTask = nil
                Logger.resource.debug("Resource finished refreshing")
            }
            
            timer?.invalidate()
            timer = nil
            refreshing = true
            updateText = updateUpdateText()

            try? await WindManager.shared.fetch()
            await updateContent()
            
            refreshing = false
            lastUpdated = Date.now
            updateText = updateUpdateText()
            
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                guard
                    let lastUpdated = self.lastUpdated,
                    let lastUpdatedFormatted = self.formatter.string(for: lastUpdated)
                else {
                    return
                }
                
                self.updateText = "Updated \(lastUpdatedFormatted)"
            }
        }

        refreshTask = task

        return try await task.value
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

    private func updateUpdateText() -> LocalizedStringResource {
        if refreshing {
            return "Checking for updates..."
        }

        return "Updated Just Now"
    }
}
