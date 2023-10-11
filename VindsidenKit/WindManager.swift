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
import OSLog

#if os(iOS)
    public typealias WindManagerResult = UIBackgroundFetchResult
#else
    public typealias WindManagerResult = Void
#endif


@objc(WindManager)
open class WindManager : NSObject {

    open var refreshInterval: TimeInterval = 0.0
    var updateTimer: Timer?
    var isUpdating:Bool = false

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


    open func startUpdating() -> Void {
        stopUpdating()

        if refreshInterval > 0 {
            let timer = Timer.scheduledTimer( timeInterval: refreshInterval, target: self, selector: #selector(WindManager.updateTimerFired(_:)), userInfo: nil, repeats: true)
            updateTimer = timer
        }

        updateNow()
    }


    open func stopUpdating() -> Void {
        if let unwrappedTimer = updateTimer {
            unwrappedTimer.invalidate()
            updateTimer = nil
        }
    }


    @objc open func updateNow() -> Void {
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

        let context = DataManager.shared.viewContext()
        do {
            let stations = try context.fetch(fetchRequest)
            return stations
        } catch {
            return [CDStation]()
        }
    }


    open func fetch(_ completionHandler: ((WindManagerResult) -> Void)? = nil) -> Void {
        if ( isUpdating ) {
            Logger.wind.debug("Already updating")
            #if os(iOS)
                completionHandler?(.newData)
            #else
                completionHandler?(())
            #endif
            return;
        }

        isUpdating = true

        let stations = activeStations()
        var remainingStations = UInt8(stations.count)

        if remainingStations <= 0 {
            isUpdating = false
            #if os(iOS)
                completionHandler?(.noData)
            #else
                completionHandler?(())
            #endif
            return
        }

        var numErrors = 0

        for station in stations {
            if let stationId = station.stationId {
                PlotFetcher().fetchForStationId(stationId.intValue, completionHandler: { (plots: [[String : String]], error: Error?) -> Void in
                    if (error != nil) {
                        Logger.wind.debug("error: \(String(describing: error))")
                        numErrors += 1
                    }

                    CDPlot.updatePlots(plots, completion: { () -> Void in
                        remainingStations -= 1

                        Logger.wind.debug("Finished with \(numErrors) errors for \(station.stationName!).")

                        if remainingStations == 0 {
                            self.isUpdating = false
                            #if os(iOS)
                                completionHandler?(.newData)
                                #else
                                completionHandler?(())
                            #endif
                        }
                    })
                })
            }
        }
    }


    open func fetchForStationId( _ stationId: Int, completionHandler: ((WindManagerResult) -> Void)? = nil ) -> Void {
        PlotFetcher().fetchForStationId(stationId) { (plots: [[String : String]], error: Error?) -> Void in
            if (error != nil) {
                Logger.wind.debug("error: \(String(describing: error))")
            } else {
                CDPlot.updatePlots(plots, completion: { () -> Void in
                    #if os(iOS)
                        completionHandler?(.newData)
                        #else
                        completionHandler?(())
                    #endif
                })
            }
        }
    }


    // MARK: - Notifications


    @objc func updateTimerFired(_ timer: Timer) -> Void {
        fetch()
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
