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
            NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
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
        let fetchRequest = CDStation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isHidden == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        let context = DataManager.shared.viewContext()
        do {
            let stations = try context.fetch(fetchRequest) as! [CDStation]
            return stations
        } catch {
            return [CDStation]()
        }
    }


    open func fetch(_ completionHandler: ((WindManagerResult) -> Void)? = nil) -> Void {
        if ( isUpdating ) {
            DLOG("Already updating")
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
                        DLOG("error: \(String(describing: error))")
                        numErrors += 1
                    }

                    CDPlot.updatePlots(plots, completion: { () -> Void in
                        remainingStations -= 1

                        if remainingStations == 0 {
                            DLOG("Finished with \(numErrors) errors.")

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
                DLOG("error: \(String(describing: error))")
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
