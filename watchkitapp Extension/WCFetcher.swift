//
//  WKFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27.08.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import WatchKit
import WatchConnectivity
import VindsidenWatchKit


public extension Notification.Name {
    static let ReceivedStations = Notification.Name("ReceivedStations")
    static let ReceivedPlots = Notification.Name("ReceivedPlots")
    static let FetchingPlots = Notification.Name("FetchingPlots")
}


class WCFetcher: NSObject, WCSessionDelegate {
    static let sharedInstance = WCFetcher()

    var connectSession: WCSession?

    override init() {
        super.init()

    }


    func activate() -> Void {
        if WCSession.isSupported() {
            connectSession = WCSession.default
            connectSession?.delegate = self
            connectSession?.activate()
            DLOG("Session: \(String(describing: connectSession))")
        } else {
            DLOG("WCSession is not supported")
        }
    }


    // MARK: - WCSession
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }


    func sessionReachabilityDidChange(_ session: WCSession) {
        DLOG("Session: \(session) - \(session.isReachable)")
    }


    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DLOG("Message: \(message)")
    }


    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {

        if let stations = applicationContext["activeStations"] as? [[String:AnyObject]] {
            CDStation.updateWithWatchContent(stations, inManagedObjectContext: Datamanager.sharedManager.managedObjectContext, completionHandler: { (visible: Bool) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    WindManager.sharedManager.fetch({ (result: WindManagerResult) -> Void in
                        NotificationCenter.default.post( name: Notification.Name.ReceivedPlots, object: nil)
                    })
                    NotificationCenter.default.post( name: Notification.Name.ReceivedStations, object: nil)
                })
            })
        }

        if let unit = applicationContext["unit"] as? Int {
            AppConfig.sharedConfiguration.applicationUserDefaults.set(unit, forKey: "selectedUnit")
            AppConfig.sharedConfiguration.applicationUserDefaults.synchronize()
        }

        DLOG("\(applicationContext)")
    }
}
