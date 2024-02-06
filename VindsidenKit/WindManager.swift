//
//  WindManager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 07/03/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import Foundation
import WatchConnectivity
import SwiftData
import WidgetKit
import OSLog

public actor WindManager {
    public static let shared = WindManager()

    private var refreshTasks: [String: Task<Void, Error>] = [:]
    private var lastFetched: Date?

    public func updateStations() async -> Bool {
        do {
            let inserted = try await Task {
                let stations = try await StationFetcher().fetch()
                let actor = await StationModelActor(modelContainer: PersistentContainer.shared.container)

                return await actor.updateWithFetchedContent(stations)
            }.value

            return inserted
        } catch {
            return false
        }
    }

    public func streamFetch() -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            continuation.onTermination = { @Sendable status in
                Logger.windManager.debug("StreamFetch terminated with status \(String(describing: status))")
            }

            Task {
                for station in await activeStations() {
                    try await fetch(station: station)
                    continuation.yield(station.1)
                }

                lastFetched = Date()
                continuation.finish()
            }
        }
    }

    public func fetch(station: (Int, String)) async throws {
        let taskId = "\(station.0)"

        Logger.windManager.debug("Start refreshing for \(station.1)")

        if let refreshTask = refreshTasks[taskId] {
            Logger.windManager.debug("Already refreshing for \(taskId)")
            return try await refreshTask.value
        }

        let task = Task { () throws -> Void in
            defer {
                refreshTasks[taskId] = nil
                Logger.windManager.debug("Finished refreshing for \(station.1)")
            }

            let hours = fetchHours()
            let modelActor = await PlotModelActor(modelContainer: PersistentContainer.shared.container)
            
            await self.fetchAndUpdatePlots(for: station.0, name: station.1, hours: hours, modelActor: modelActor)

            Task { @MainActor in
                try? PersistentContainer.shared.container.mainContext.save()
            }
        }

        refreshTasks[taskId] = task

        return try await task.value
    }

    @MainActor
    private func activeStations() async -> [(Int, String)] {
        let result = Station.visible(in: PersistentContainer.shared.container.mainContext)

        return result.compactMap { (Int($0.stationId), $0.stationName!) }
    }

    public func fetchHours() -> Int {
        let maxHours = Int(AppConfig.Global.plotHistory)

        return maxHours
    }

    private func fetchAndUpdatePlots(for stationId: Int, name: String, hours: Int, modelActor: PlotModelActor) async {
        do {
            let plots = try await PlotFetcher().fetchForStationId(stationId, hours: hours)
            let num = try await modelActor.updatePlots(plots)

            Logger.windManager.debug("Finished with \(num) new plots for \(name).")
        } catch {
            Logger.windManager.debug("error: \(String(describing: error)) for \(name).")
        }
    }
}
