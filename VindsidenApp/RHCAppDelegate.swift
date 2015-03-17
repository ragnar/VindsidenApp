//
//  RHCAppDelegate.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit
import AFNetworking


@UIApplicationMain
class RHCAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let _formatterQueue = dispatch_queue_create("formatter queue", nil);


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true

        self.window?.tintColor = UIColor.vindsidenGloablTintColor()

        if AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit") == 0 {
            AppConfig.sharedConfiguration.applicationUserDefaults.setInteger(SpeedConvertion.ToMetersPerSecond.rawValue, forKey: "selectedUnit")
            AppConfig.sharedConfiguration.applicationUserDefaults.synchronize()
        }

        Datamanager.sharedManager().cleanupPlots { () -> Void in
            WindManager.sharedManager.refreshInterval = 60
            WindManager.sharedManager.startUpdating()
        }

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


    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> Int {
        if let rootVC = self.window?.rootViewController as? RHCNavigationViewController {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.Portrait.rawValue);
        }
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
        WindManager.sharedManager.fetch { (result: UIBackgroundFetchResult) -> Void in
            DLOG("Fetch finished")
            completionHandler(result)
        }
    }


    // MARK: - 

    
    func openLaunchOptionsURL( url: NSURL) -> Bool {
        let ident = url.pathComponents?.last as String
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
        let controller = primaryViewController()

        if let pc = nc?.presentedViewController {
            nc?.dismissViewControllerAnimated(false, completion: { () -> Void in
                controller!.scrollToStation(station!)
            })
        } else {
            controller!.scrollToStation(station!)
        }

        return true
    }


    // MARK: - Restoration


    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }


    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    
    // MARK: - NSUserActivity

    func application(application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }


    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]!) -> Void) -> Bool {
        DLOG("Activity: \(userActivity.userInfo)")

        if let userInfo = userActivity.userInfo {
            if let urlString = userInfo["urlToActivate"] as? String {
                let url = NSURL(string: urlString)
                let success = openLaunchOptionsURL(url!)
                return success
            }
        }
        return false
    }

    
    func application(application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: NSError) {
        DLOG("did fail to continue: \(userActivityType), \(error)")
    }


    func primaryViewController() -> RHCViewController? {
        let nc = self.window?.rootViewController as? UINavigationController
        let controller = nc?.viewControllers.first as? RHCViewController
        return controller
    }
}
