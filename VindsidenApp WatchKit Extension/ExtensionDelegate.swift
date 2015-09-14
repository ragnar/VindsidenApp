//
//  ExtensionDelegate.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import WatchKit
import VindsidenWatchKit


class ExtensionDelegate: NSObject, WKExtensionDelegate {

    var timestamp: NSTimeInterval = 0

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }


    func applicationDidBecomeActive() {

        WCFetcher.sharedInstance.activate()

        if NSDate().timeIntervalSinceReferenceDate < timestamp + 60 {
            return
        }

        timestamp = NSDate().timeIntervalSinceReferenceDate

        Datamanager.sharedManager().cleanupPlots { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(WCFetcherNotification.FetchingPlots, object: nil)
            WindManager.sharedManager.fetch({ (result: WindManagerResult) -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(WCFetcherNotification.ReceivedPlots, object: nil)
            })
        }
    }


    func applicationWillResignActive() {
        PlotFetcher.invalidate()
        StationFetcher.invalidate()
    }
}
