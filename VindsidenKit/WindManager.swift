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
    var isUpdating: Bool = false

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


    @MainActor
    func activeStations() -> [CDStation] {
        let fetchRequest: NSFetchRequest<CDStation> = CDStation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isHidden == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        do {
            let context = DataManager.shared.viewContext()
            let stations = try context.fetch(fetchRequest)
            return stations
        } catch {
            return [CDStation]()
        }
    }

    @MainActor
    public func fetch() async {
        if ( isUpdating ) {
            Logger.wind.debug("Already updating")
            return
        }

        isUpdating = true

        let stations = activeStations()
        var remainingStations = stations.count

        if remainingStations <= 0 {
            isUpdating = false
            return
        }

        for station in stations {
            guard let stationId = station.stationId else {
                continue
            }

            do {
                let plots = try await PlotFetcher().fetchForStationId(stationId.intValue)
                let num = try await CDPlot.updatePlots(plots)

                Logger.wind.debug("Finished with \(num) new plots for \(station.stationName!).")
            } catch {
                Logger.wind.debug("error: \(String(describing: error)) for \(station.stationName!).")
            }

            remainingStations -= 1

            if remainingStations <= 0 {
                self.isUpdating = false
            }
        }

        return
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
