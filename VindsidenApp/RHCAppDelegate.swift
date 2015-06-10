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


    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        if let _ = self.window?.rootViewController as? RHCNavigationViewController {
            return .AllButUpsideDown
        } else {
            return .Portrait
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
            completionHandler(result)
        }
    }


    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: ([NSObject : AnyObject]?) -> Void) {
        let taskID = application.beginBackgroundTaskWithExpirationHandler({})

        if  let unwrapped = userInfo, let interface = unwrapped["interface"] as? String {
            switch (interface) {
            case "glance":
                WindManager.sharedManager.fetchForStationId(unwrapped["station"] as! Int) { (result: UIBackgroundFetchResult) -> Void in
                    reply(["result": "updated"])
                    application.endBackgroundTask(taskID)
                }
            case "main":
                WindManager.sharedManager.fetch { (result: UIBackgroundFetchResult) -> Void in
                    reply(["result": "updated"])
                    application.endBackgroundTask(taskID)
                }
            case "graph":
                let graph = [
                    "result": "updated",
                    "graph": generateGraphImage(unwrapped["station"] as! Int, screenSize: CGRectFromString(unwrapped["bounds"] as! String), scale: unwrapped["scale"] as! CGFloat)
                    ] as [NSObject:AnyObject]

                reply(graph)
                application.endBackgroundTask(taskID)
            default:
                reply(["result": "not_updated"])
                application.endBackgroundTask(taskID)
            }
        }
    }


    func generateGraphImage( stationId: Int, screenSize: CGRect, scale: CGFloat ) -> NSData {
        let graphImage: GraphImage
        let imageSize = CGSizeMake( CGRectGetWidth(screenSize), CGRectGetHeight(screenSize) - 40.0)

        if let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
            let inDate = NSDate().dateByAddingTimeInterval(-1*4*3600)
            let inputComponents = gregorian.components([.Year, .Month, .Day, .Hour], fromDate: inDate)
            let outDate = gregorian.dateFromComponents(inputComponents)!

            let fetchRequest = NSFetchRequest(entityName: "CDPlot")
            fetchRequest.predicate = NSPredicate(format: "station.stationId = %ld AND plotTime >= %@", stationId, outDate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "plotTime", ascending: false)]

            do {
                let result = try Datamanager.sharedManager().managedObjectContext?.executeFetchRequest(fetchRequest) as! [CDPlot]
                graphImage = GraphImage(size: imageSize, scale: scale, plots: result)
            } catch {
                graphImage = GraphImage(size: imageSize, scale: scale)
            }
        } else {
            graphImage = GraphImage(size: imageSize, scale: scale)
        }

        let image = graphImage.drawImage()
        return UIImagePNGRepresentation(image)!
    }


    // MARK: - 

    
    func openLaunchOptionsURL( url: NSURL) -> Bool {
        let ident = url.pathComponents?.last as String!
        var station: CDStation?

        if let stationId = Int(ident) {
            station = CDStation.existingStation(stationId, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
        } else {
            station = CDStation.searchForStation(ident, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
        }

        if  let found = station {
            if found.isHidden.boolValue == true {
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

    
    // MARK: - NSUserActivity

    func application(application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }


    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
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
