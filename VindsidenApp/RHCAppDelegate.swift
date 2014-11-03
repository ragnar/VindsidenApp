//
//  RHCAppDelegate.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit


@UIApplicationMain
class RHCAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let _formatterQueue = dispatch_queue_create("formatter queue", nil);

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true

        self.window?.tintColor = UIColor.vindsidenGloablTintColor()

        if Datamanager.sharedManager().sharedDefaults.integerForKey("selectedUnit") == 0 {
            Datamanager.sharedManager().sharedDefaults.setInteger(SpeedConvertion.ToMetersPerSecond.rawValue, forKey: "selectedUnit")
            Datamanager.sharedManager().sharedDefaults.synchronize()
        }


        Datamanager.sharedManager().cleanupPlots()

        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        return true
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {

        if let options = launchOptions {
            if let url = options[UIApplicationLaunchOptionsURLKey] as? NSURL {
                if let range = url.host?.rangeOfString("station", options: .CaseInsensitiveSearch) {
                    return true
                } else {
                    return false
                }
            }
        }

        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {

        if let range = url.host?.rangeOfString("station", options: .CaseInsensitiveSearch) {
            return openLaunchOptionsURL(url)
        }

        return false
    }

    func applicationWillResignActive(application: UIApplication) {
        RHEVindsidenAPIClient.defaultManager().background = true
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        RHEVindsidenAPIClient.defaultManager().background = false
    }

    func applicationWillTerminate(application: UIApplication) {
        Datamanager.sharedManager().saveContext()
    }


    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let nc = self.window?.rootViewController as UINavigationController
        if let vc = nc.viewControllers.first as? RHCViewController {
            vc.updateContentWithCompletionHandler(completionHandler)
        }
    }

    // MARK: - 

    func openLaunchOptionsURL( url: NSURL) -> Bool {
        let ident = url.pathComponents.last as String
        var station: CDStation?

        if let stationId = ident.toInt() {
            station = CDStation.existingStation(stationId, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
        } else {
            station = CDStation.searchForStation(ident, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
        }

        if  let found = station {
            if found.isHidden.boolValue == true {
                found.managedObjectContext?.performBlockAndWait({ () -> Void in
                    found.isHidden = false
                    found.managedObjectContext?.save(nil)
                })
            }
        } else {
            return false
        }


        let nc = self.window?.rootViewController as? UINavigationController
        let controller = nc?.viewControllers.first as? RHCViewController

        if let pc = nc?.presentedViewController {
            nc?.dismissViewControllerAnimated(false, completion: { () -> Void in
                controller!.scrollToStation(station!)
            })
        } else {
            controller!.scrollToStation(station!)
        }

        return true
    }
}
