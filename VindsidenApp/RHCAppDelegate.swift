//
//  RHCAppDelegate.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit
import VindsidenKit
import WatchConnectivity
import CoreSpotlight


@UIApplicationMain
class RHCAppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    var connectionSession: WCSession?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        NetworkIndicator.defaultManager().startListening()

        self.window?.tintColor = UIColor.vindsidenGloablTintColor()

        if AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit") == 0 {
            AppConfig.sharedConfiguration.applicationUserDefaults.setInteger(SpeedConvertion.ToMetersPerSecond.rawValue, forKey: "selectedUnit")
            AppConfig.sharedConfiguration.applicationUserDefaults.synchronize()
        }

        if WCSession.isSupported() {
            let connectionSession = WCSession.defaultSession()

            //if connectionSession.paired && connectionSession.watchAppInstalled {
                connectionSession.delegate = self
                connectionSession.activateSession()
            //}
        }

        Datamanager.sharedManager().cleanupPlots { () -> Void in
            WindManager.sharedManager.refreshInterval = 60
            WindManager.sharedManager.startUpdating()
        }

        Datamanager.sharedManager().indexActiveStations()

        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        return true
    }


    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {

        if let options = launchOptions {
            if let url = options[UIApplicationLaunchOptionsURLKey] as? NSURL {
                if let _ = url.host?.rangeOfString("station", options: .CaseInsensitiveSearch) {
                    return true
                } else {
                    return false
                }
            }
        }

        return true
    }


    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        if let _ = url.host?.rangeOfString("station", options: .CaseInsensitiveSearch) {
            return openLaunchOptionsURL(url)
        }

        return false
    }


    func applicationWillResignActive(application: UIApplication) {
    }


    func applicationDidEnterBackground(application: UIApplication) {
        PlotFetcher.invalidate()
        StationFetcher.invalidate()
    }


    func applicationWillEnterForeground(application: UIApplication) {
    }


    func applicationDidBecomeActive(application: UIApplication) {
        if WCSession.isSupported() {
            let connectionSession = WCSession.defaultSession()

//            if connectionSession.paired && connectionSession.watchAppInstalled {
            connectionSession.delegate = self
            connectionSession.activateSession()
//            }
        }
    }


    func applicationWillTerminate(application: UIApplication) {
        Datamanager.sharedManager().saveContext()
        NetworkIndicator.defaultManager().stopListening()
    }


    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        WindManager.sharedManager.fetch { (result: UIBackgroundFetchResult) -> Void in
            completionHandler(result)
        }
    }


    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: ([NSObject : AnyObject]?) -> Void) {
        let taskID = application.beginBackgroundTaskWithExpirationHandler({})

        reply(["result": "not_updated"])
        application.endBackgroundTask(taskID)
    }


    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        guard let window = window else {
            return .AllButUpsideDown
        }

        if  window.traitCollection.userInterfaceIdiom == .Pad  {
            return .All
        }

        return .AllButUpsideDown
    }


    // MARK: -

    
    func openLaunchOptionsURL( url: NSURL) -> Bool {
        let ident = url.pathComponents?.last as String!
        var station: CDStation?

        if let stationId = Int(ident) {
            do {
                station = try CDStation.existingStationWithId(stationId, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
            } catch {
            }
        } else {
            station = CDStation.searchForStationName(ident, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
        }

        if  let found = station {
            if let hidden = found.isHidden where hidden.boolValue == true {
                found.managedObjectContext?.performBlockAndWait({ () -> Void in
                    found.isHidden = false
                    do {
                        try found.managedObjectContext?.save()
                    } catch {
                        DLOG("Save failed")
                    }
                })
            }
        } else {
            return false
        }


        let nc = self.window?.rootViewController as? UINavigationController
        let controller = primaryViewController()

        if let _ = nc?.presentedViewController {
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


    // MARK: - WC Session


    func sessionWatchStateDidChange(session: WCSession) {
        DLOG("Session: \(session)")
    }

    func sessionReachabilityDidChange(session: WCSession) {
        DLOG("Session: \(session)")
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        DLOG("Session: \(message)")
        replyHandler(["result": "not_updated"])
    }


    // MARK: - NSUserActivity

    override func updateUserActivityState(activity: NSUserActivity) {
        DLOG("\(activity)")
    }

    func application(application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }


    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        DLOG("Activity: \(userActivity.activityType) - \(userActivity.userInfo)")


        if userActivity.activityType == CSSearchableItemActionType, let userInfo = userActivity.userInfo, let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String {
            DLOG("URL STRING: \(urlString)")
            let url = NSURL(string: urlString)
            let success = openLaunchOptionsURL(url!)

            return success
        } else if let userInfo = userActivity.userInfo, let urlString = userInfo["urlToActivate"] as? String {
            let url = NSURL(string: urlString)
            let success = openLaunchOptionsURL(url!)

            return success
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
