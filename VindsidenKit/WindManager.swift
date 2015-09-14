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
public class WindManager : NSObject {

    public var refreshInterval: NSTimeInterval = 0.0
    var updateTimer: NSTimer?
    var isUpdating:Bool = false

    public class var sharedManager: WindManager {
        struct Singleton {
            static let sharedManager = WindManager()
        }

        return Singleton.sharedManager
    }


    override init() {
        super.init()
        #if os(iOS)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidEnterBackground:"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationWillEnterForeground:"), name: UIApplicationWillEnterForegroundNotification, object: nil)
        #endif
    }


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    public func startUpdating() -> Void {
        stopUpdating()

        if refreshInterval > 0 {
            let timer = NSTimer.scheduledTimerWithTimeInterval( refreshInterval, target: self, selector: Selector("updateTimerFired:"), userInfo: nil, repeats: true)
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


    public func updateNow() -> Void {
        if let unwrappedTimer = updateTimer {
            unwrappedTimer.fire()
        } else {
            updateTimerFired(NSTimer())
        }
    }


    func activeStations() -> [CDStation] {
        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.predicate = NSPredicate(format: "isHidden == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        let context = Datamanager.sharedManager().managedObjectContext
        do {
            let stations = try context.executeFetchRequest(fetchRequest) as! [CDStation]
            return stations
        } catch {
            return [CDStation]()
        }
    }


    public func fetch(completionHandler: ((WindManagerResult) -> Void)? = nil) -> Void {
        if ( isUpdating ) {
            DLOG("Already updating")
            #if os(iOS)
                completionHandler?(.NewData)
            #else
                completionHandler?()
            #endif
            return;
        }

        isUpdating = true

        let stations = activeStations()
        var remainingStations = UInt8(stations.count)

        if remainingStations <= 0 {
            isUpdating = false
            #if os(iOS)
                completionHandler?(.NoData)
            #else
                completionHandler?()
            #endif
            return
        }

        var numErrors = 0

        for station in stations {
            if let stationId = station.stationId {
                PlotFetcher().fetchForStationId(stationId.integerValue, completionHandler: { (plots: [[String : String]], error: NSError?) -> Void in
                    if (error != nil) {
                        DLOG("error: \(error)")
                        numErrors += 1
                    }

                    CDPlot.updatePlots(plots, completion: { () -> Void in
                        remainingStations -= 1

                        if remainingStations == 0 {
                            DLOG("Finished with \(numErrors) errors.")

                            self.isUpdating = false
                            #if os(iOS)
                                completionHandler?(.NewData)
                                #else
                                completionHandler?()
                            #endif
                        }
                    })
                })
            }
        }
    }


    public func fetchForStationId( stationId: Int, completionHandler: ((WindManagerResult) -> Void)? = nil ) -> Void {
        PlotFetcher().fetchForStationId(stationId) { (plots: [[String : String]], error: NSError?) -> Void in
            if (error != nil) {
                DLOG("error: \(error)")
            } else {
                CDPlot.updatePlots(plots, completion: { () -> Void in
                    #if os(iOS)
                        completionHandler?(.NewData)
                        #else
                        completionHandler?()
                    #endif
                })
            }
        }
    }


    // MARK: - Notifications


    func updateTimerFired(timer: NSTimer) -> Void {
        fetch()
    }

    #if os(iOS)
    func applicationWillEnterForeground( application: UIApplication) -> Void {
        startUpdating()
    }


    func applicationDidEnterBackground( application: UIApplication) -> Void {
        stopUpdating()
    }
    #endif
}
