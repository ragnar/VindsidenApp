//
//  WindManager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 07/03/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import Foundation
import WatchConnectivity
import CoreData
import WidgetKit
import OSLog

@objc(WindManager)
public class WindManager : NSObject {
    public var refreshInterval: TimeInterval = 0.0
    private var updateTimer: Timer?
    private var isUpdating: Bool = false
    private var lastFetched: Date?

    @objc public static let sharedManager = WindManager()

#if os(iOS)
    public var observer: UserObservable?
#endif

    override init() {
        super.init()
        #if os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func startUpdating() -> Void {
        stopUpdating()

        if refreshInterval > 0 {
            let timer = Timer.scheduledTimer( timeInterval: refreshInterval, target: self, selector: #selector(WindManager.updateTimerFired(_:)), userInfo: nil, repeats: true)
            updateTimer = timer
        }

        updateNow()
    }

    public func stopUpdating() -> Void {
        if let unwrappedTimer = updateTimer {
            unwrappedTimer.invalidate()
            updateTimer = nil
        }
    }

    @objc public func updateNow() -> Void {
        if let unwrappedTimer = updateTimer {
            unwrappedTimer.fire()
        } else {
            updateTimerFired(Timer())
        }
    }

    func activeStations() async -> [(Int, String)] {
        return await DataManager.shared.container.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<CDStation> = CDStation.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isHidden == NO")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

            do {
                let stations = try context.fetch(fetchRequest)
                return stations.compactMap { ($0.stationId!.intValue, $0.stationName!) }
            } catch {
                return []
            }
        }
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

    @MainActor
    public func fetch(stationId: Int? = nil) async {
        if isUpdating {
            Logger.wind.debug("Already updating")
            return
        }

        isUpdating = true

        @Sendable
        @MainActor
        func update(stationId: Int, name: String, hours: Int) async {
            do {
                let plots = try await PlotFetcher().fetchForStationId(stationId, hours: hours)
                let num = try await CDPlot.updatePlots(plots)

                Logger.wind.debug("Finished with \(num) new plots for \(name).")
            } catch {
                Logger.wind.debug("error: \(String(describing: error)) for \(name).")
            }
        }

        let stations: [(Int, String)]

        if let stationId {
            stations = [(stationId, "Widget loading")]
        } else {
            stations = await activeStations()
        }

        let hours = fetchHours()

        await withTaskGroup(
            of: Void.self,
            returning: Void.self
        ) { group in
            for station in stations {
                group.addTask {
                    await update(stationId: station.0, name: station.1, hours: hours)
                }
            }

            await group.waitForAll()
        }
        
        lastFetched = Date()
        isUpdating = false
    }

    // MARK: - Notifications


    @objc func updateTimerFired(_ timer: Timer) -> Void {
        Task { @MainActor in
            await fetch()
#if os(iOS)
            observer?.lastChanged = Date()
            WidgetCenter.shared.reloadAllTimelines()
#endif
        }
    }

    #if os(iOS)
    @objc func applicationWillEnterForeground( _ application: UIApplication) -> Void {
        startUpdating()
    }


    @objc func applicationDidEnterBackground( _ application: UIApplication) -> Void {
        stopUpdating()
    }
    #endif
}
