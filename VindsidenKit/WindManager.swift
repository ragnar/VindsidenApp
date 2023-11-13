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
            let stations = try await StationFetcher().fetch()
            let inserted = await Task { @MainActor in
                return Station.updateWithFetchedContent(stations)
            }.value

            return inserted
        } catch {
            return false
        }
    }

    public func fetch(stationId: Int? = nil) async throws {
        let taskId = "\(stationId ?? -9999)"

        Logger.windManager.debug("Start refreshing for \(taskId)")

        if let refreshTask = refreshTasks[taskId] {
            Logger.windManager.debug("Already refreshing for \(taskId)")
            return try await refreshTask.value
        }

        let task = Task { () throws -> Void in
            defer {
                refreshTasks[taskId] = nil
                Logger.windManager.debug("Finished refreshing for \(taskId)")
            }

            let hours = fetchHours()
            let stations: [(Int, String)]

            if let stationId {
                stations = [(stationId, "Widget loading")]
            } else {
                stations = await activeStations()
            }

            await withTaskGroup(
                of: Void.self,
                returning: Void.self
            ) { group in
                for station in stations {
                    group.addTask {
                        await self.update(stationId: station.0, name: station.1, hours: hours)
                    }
                }

                await group.waitForAll()
            }

            lastFetched = Date()
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

        guard let lastFetched else {
            return maxHours
        }

        let components = Calendar.current.dateComponents([.hour], from: lastFetched, to: Date())

        guard let hours = components.hour else {
            return maxHours
        }

        if hours >= maxHours {
            return maxHours
        } else if hours <= 2 {
            return 3
        }

        return hours
    }

    @Sendable
    @MainActor
    private func update(stationId: Int, name: String, hours: Int) async {
        do {
            let plots = try await PlotFetcher().fetchForStationId(stationId, hours: hours)
            let num = try await Plot.updatePlots(plots)

            Logger.windManager.debug("Finished with \(num) new plots for \(name).")
        } catch {
            Logger.windManager.debug("error: \(String(describing: error)) for \(name).")
        }
    }
}
