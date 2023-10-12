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
import WidgetKit
import OSLog

@UIApplicationMain
class RHCAppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    var connectionSession: WCSession?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.window?.tintColor = UIColor.vindsidenGloablTintColor()

        if AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit") == 0 {
            AppConfig.sharedConfiguration.applicationUserDefaults.set(SpeedConvertion.toMetersPerSecond.rawValue, forKey: "selectedUnit")
            AppConfig.sharedConfiguration.applicationUserDefaults.synchronize()
        }

        if WCSession.isSupported() {
            let connectionSession = WCSession.default

            //if connectionSession.paired && connectionSession.watchAppInstalled {
                connectionSession.delegate = self
                connectionSession.activate()
            //}
        }

        DataManager.shared.cleanupPlots {
            WindManager.sharedManager.refreshInterval = 60
            WindManager.sharedManager.startUpdating()
        }

        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        var performAdditionalHandling = true

        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem, let rootViewController = primaryViewController() {
            let didHandleShortcutItem = ShortcutItemHandler.handle(shortcutItem, with: rootViewController)
            performAdditionalHandling = !didHandleShortcutItem
        }

        ShortcutItemHandler.updateDynamicShortcutItems(for: application)

        return performAdditionalHandling
    }


    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let options = launchOptions {
            if let url = options[UIApplication.LaunchOptionsKey.url] as? URL {
                if let _ = url.host?.range(of: "station", options: .caseInsensitive) {
                    return true
                } else {
                    return false
                }
            }
        }

        return true
    }


    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

        if let _ = url.host?.range(of: "station", options: .caseInsensitive) {
            return openLaunchOptionsURL(url)
        }

        return false
    }


    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        AppConfig.sharedConfiguration.presentReviewControllerIfCriteriaIsMet()
    }


    func applicationDidBecomeActive(_ application: UIApplication) {
        if WCSession.isSupported() {
            let connectionSession = WCSession.default

//            if connectionSession.paired && connectionSession.watchAppInstalled {
            connectionSession.delegate = self
            connectionSession.activate()
//            }
        }
    }


    func applicationWillTerminate(_ application: UIApplication) {
        DataManager.shared.saveContext()
    }


    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task { @MainActor in
            await WindManager.sharedManager.fetch()
            WidgetCenter.shared.reloadTimelines(ofKind: "VindsidenWidget")
            completionHandler(.newData)
        }
    }

    func application(_ application: UIApplication, handleWatchKitExtensionRequest userInfo: [AnyHashable: Any]?, reply: @escaping ([AnyHashable: Any]?) -> Void) {
        let taskID = application.beginBackgroundTask(expirationHandler: {})

        reply(["result": "not_updated"])
        application.endBackgroundTask(taskID)
    }


    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        guard let window = window else {
            return .allButUpsideDown
        }

        if  window.traitCollection.userInterfaceIdiom == .pad  {
            return .all
        }

        return .allButUpsideDown
    }


    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        var didHandleShortcutItem = false

        let nc = self.window?.rootViewController as? UINavigationController
        let controller = primaryViewController()

        if let _ = nc?.presentedViewController {
            nc?.dismiss(animated: false, completion: { () -> Void in
                didHandleShortcutItem = ShortcutItemHandler.handle(shortcutItem, with: controller!)
            })
        } else {
            didHandleShortcutItem = ShortcutItemHandler.handle(shortcutItem, with: controller!)
        }

        completionHandler(didHandleShortcutItem)
    }


    // MARK: -

    
    func openLaunchOptionsURL( _ url: URL) -> Bool {
        guard let ident = url.pathComponents.last else {
            return false
        }

        var station: CDStation?

        if let stationId = Int(ident) {
            do {
                station = try CDStation.existingStationWithId(stationId, inManagedObjectContext: DataManager.shared.viewContext())
            } catch {
            }
        } else {
            station = CDStation.searchForStationName(ident, inManagedObjectContext: DataManager.shared.viewContext())
        }

        if  let found = station {
            if let hidden = found.isHidden, hidden.boolValue == true {
                found.managedObjectContext?.performAndWait({ () -> Void in
                    found.isHidden = false
                    do {
                        try found.managedObjectContext?.save()
                    } catch {
                        Logger.debugging.debug("Save failed")
                    }
                })
            }
        } else {
            return false
        }


        let nc = self.window?.rootViewController as? UINavigationController
        let controller = primaryViewController()

        if let _ = nc?.presentedViewController {
            nc?.dismiss(animated: false, completion: { () -> Void in
                controller!.scroll(to: station!)
            })
        } else {
            controller!.scroll(to: station!)
        }

        return true
    }


    // MARK: - Restoration


    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }


    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }


    // MARK: - WC Session


    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Logger.debugging.debug("Session: \(session)")
    }


    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.debugging.debug("Session: \(session)")
    }


    func sessionDidDeactivate(_ session: WCSession) {
        Logger.debugging.debug("Session: \(session)")
    }


    func sessionWatchStateDidChange(_ session: WCSession) {
        Logger.debugging.debug("Session: \(session)")
    }


    func sessionReachabilityDidChange(_ session: WCSession) {
        Logger.debugging.debug("Session: \(session)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Logger.debugging.debug("Session: \(message)")
        replyHandler(["result": "not_updated"])
    }


    // MARK: - NSUserActivity

    override func updateUserActivityState(_ activity: NSUserActivity) {
        Logger.debugging.debug("\(activity)")
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }


    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Logger.debugging.debug("Activity: \(userActivity.activityType) - \(String(describing: userActivity.userInfo))")


        if userActivity.activityType == CSSearchableItemActionType, let userInfo = userActivity.userInfo, let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String {
            Logger.debugging.debug("URL STRING: \(urlString)")
            let url = URL(string: urlString)
            let success = openLaunchOptionsURL(url!)

            return success
        } else if let userInfo = userActivity.userInfo, let urlString = userInfo["urlToActivate"] as? String {
            let url = URL(string: urlString)
            let success = openLaunchOptionsURL(url!)

            return success
        }

        return false
    }

    
    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        Logger.debugging.debug("did fail to continue: \(userActivityType), \(error)")
    }


    func primaryViewController() -> RHCViewController? {
        let nc = self.window?.rootViewController as? UINavigationController
        let controller = nc?.viewControllers.first as? RHCViewController
        return controller
    }


    @objc func updateShortcutItems() {
        ShortcutItemHandler.updateDynamicShortcutItems(for: UIApplication.shared)
    }
}
