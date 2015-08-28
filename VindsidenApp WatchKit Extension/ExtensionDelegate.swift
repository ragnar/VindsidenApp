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


    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.

        WCFetcher.sharedInstance.activate()

        Datamanager.sharedManager().cleanupPlots { () -> Void in
            WindManager.sharedManager.updateNow()
        }
    }


    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }


    }
