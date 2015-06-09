//
//  WindManager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 07/03/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import Foundation

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidEnterBackground:"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationWillEnterForeground:"), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    public func startUpdating() -> Void {
        stopUpdating()

        if refreshInterval > 0 {
            var timer = NSTimer.scheduledTimerWithTimeInterval( refreshInterval, target: self, selector: Selector("updateTimerFired:"), userInfo: nil, repeats: true)
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

        var stations = context?.executeFetchRequest(fetchRequest, error: nil) as! [CDStation]
        return stations ?? [CDStation]()
    }


    public func fetch(completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) -> Void {
        if ( isUpdating ) {
            DLOG("Already updating")
            completionHandler?(.NewData)
            return;
        }

        isUpdating = true

        let stations = activeStations()
        var remainingStations = UInt8(stations.count)

        if remainingStations <= 0 {
            isUpdating = false
            completionHandler?(.NoData)
            return
        }

        for station in stations {
            let complete = { (success:Bool, plots: [AnyObject]!) -> Void in
                CDPlot.updatePlots(plots ?? [CDPlot](), completion: { () -> Void in
                    remainingStations -= 1

                    if remainingStations == 0 {
                        DLOG("Finished")

                        self.isUpdating = false
                        completionHandler?(.NewData)
                    }
                })
            }

            let error = { (cancelled:Bool, error: NSError!) -> Void in
                DLOG("error: \(error)")
            }

            RHEVindsidenAPIClient.defaultManager().fetchStationsPlotsForStation(station.stationId, completion: complete, error: error)
        }
    }


    public func fetchForStationId( stationId: Int, completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil ) -> Void {
        RHEVindsidenAPIClient.defaultManager().fetchStationsPlotsForStation(stationId, completion: { (success:Bool, plots: [AnyObject]!) -> Void in
            CDPlot.updatePlots(plots, completion: { () -> Void in
                completionHandler?(.NewData)
            })
            }, error: { (cancelled: Bool, error: NSError!) -> Void in
                completionHandler?(.NewData)
        })
    }


    // MARK: - Notifications


    func updateTimerFired(timer: NSTimer) -> Void {
        fetch()
    }


    func applicationWillEnterForeground( application: UIApplication) -> Void {
        startUpdating()
    }


    func applicationDidEnterBackground( application: UIApplication) -> Void {
        stopUpdating()
    }
}

