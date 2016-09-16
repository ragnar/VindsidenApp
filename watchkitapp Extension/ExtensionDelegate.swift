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


    func handleBackgroundTasks(backgroundTasks: Set<WKRefreshBackgroundTask>) {

        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                WindManager.sharedManager.fetch({ (result: WindManagerResult) -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(WCFetcherNotification.ReceivedPlots, object: nil)
                    backgroundTask.setTaskCompleted()
                })

//            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
//                // Snapshot tasks have a unique completion call, make sure to set your expiration date
//                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
//            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
//                // Be sure to complete the connectivity task once you’re done.
//                connectivityTask.setTaskCompleted()
//            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
//                // Be sure to complete the URL session task once you’re done.
//                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
}
