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

    var timestamp: TimeInterval = 0

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }


    func applicationDidBecomeActive() {

        WCFetcher.sharedInstance.activate()
        scheduleRefresh()

        if Date().timeIntervalSinceReferenceDate < timestamp + 60 {
            return
        }

        timestamp = Date().timeIntervalSinceReferenceDate

        DataManager.shared.cleanupPlots { () -> Void in
            NotificationCenter.default.post(name: Notification.Name.FetchingPlots, object: nil)

            Task { @MainActor in
                await WindManager.sharedManager.fetch()
                NotificationCenter.default.post( name: Notification.Name.ReceivedPlots, object: nil)
            }
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {

        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                if (WKExtension.shared().applicationState != .background) {
                    if #available(watchOSApplicationExtension 4.0, *) {
                        backgroundTask.setTaskCompletedWithSnapshot(false)
                    } else {
                        backgroundTask.setTaskCompleted()
                    }
                    return
                }

                Task { @MainActor in
                    await WindManager.sharedManager.fetch()
                    NotificationCenter.default.post( name: Notification.Name.ReceivedPlots, object: nil)

                    if #available(watchOSApplicationExtension 4.0, *) {
                        backgroundTask.setTaskCompletedWithSnapshot(false)
                    } else {
                        backgroundTask.setTaskCompleted()
                    }
                    self.scheduleRefresh()
                }

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
                if #available(watchOSApplicationExtension 4.0, *) {
                    task.setTaskCompletedWithSnapshot(false)
                } else {
                    task.setTaskCompleted()
                }
            }
        }
    }


    func scheduleRefresh() {
//        let fireDate = Date(timeIntervalSinceNow: 60.0*30.0)
//        let userInfo = ["reason" : "background update"] as NSDictionary
//
//        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
//            if error != nil {
//                Logger.debugging.debug("Schedule background failed: \(String(describing: error))")
//            }
//        }
    }
}
