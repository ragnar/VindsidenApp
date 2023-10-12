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

    @objc func updateNow() -> Void {
        if let unwrappedTimer = updateTimer {
            unwrappedTimer.fire()
        } else {
            updateTimerFired(Timer())
        }
    }


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

    public func fetch() async {
        if ( isUpdating ) {
            Logger.wind.debug("Already updating")
            return
        }

        isUpdating = true

        let stations = activeStations()
        var remainingStations = UInt8(stations.count)

        if remainingStations <= 0 {
            isUpdating = false
            return
        }

        var numErrors = 0

        for station in stations {
            guard let stationId = station.stationId else {
                continue
            }

            do {
                let plots = try await PlotFetcher().fetchForStationId(stationId.intValue)

                try CDPlot.updatePlots(plots)

                remainingStations -= 1

                Logger.wind.debug("Finished with \(numErrors) errors for \(station.stationName!).")

                if remainingStations <= 0 {
                    self.isUpdating = false
                }
            } catch {
                Logger.wind.debug("error: \(String(describing: error))")
                numErrors += 1
            }
        }

        return
    }

    // MARK: - Notifications


    @objc func updateTimerFired(_ timer: Timer) -> Void {
        Task {
            await fetch()
#if os(iOS)
            WidgetCenter.shared.reloadTimelines(ofKind: "VindsidenWidget")
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
