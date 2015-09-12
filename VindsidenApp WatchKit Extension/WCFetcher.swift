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


struct WCFetcherNotification {
    static let ReceivedStations = "ReceivedStations"
    static let ReceivedPlots = "ReceivedPlots"
    static let FetchingPlots = "FetchingPlots"
}


class WCFetcher: NSObject, WCSessionDelegate {
    static let sharedInstance = WCFetcher()

    var connectSession: WCSession?

    override init() {
        super.init()

    }


    func activate() -> Void {
        if WCSession.isSupported() {
            connectSession = WCSession.defaultSession()
            connectSession?.delegate = self
            connectSession?.activateSession()
            DLOG("Session: \(connectSession)")
        } else {
            DLOG("WCSession is not supported")
        }
    }


    // MARK: - WCSession


    func sessionWatchStateDidChange(session: WCSession) {
        DLOG("Session: \(session)")
    }


    func sessionReachabilityDidChange(session: WCSession) {
        DLOG("Session: \(session) - \(session.reachable)")
    }


    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        DLOG("Message: \(message)")
    }


    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let stations = applicationContext["activeStations"] as? [[String:AnyObject]] {
            CDStation.updateWithWatchContent(stations, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext, completionHandler: { (visible: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    WindManager.sharedManager.fetch({ (result: WindManagerResult) -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName( WCFetcherNotification.ReceivedPlots, object: nil)
                    })
                    NSNotificationCenter.defaultCenter().postNotificationName( WCFetcherNotification.ReceivedStations, object: nil)
                })
            })
        } else {
            DLOG("\(applicationContext)")
        }
    }
}
