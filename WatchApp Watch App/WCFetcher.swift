//
//  WKFetcher.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27.08.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import WatchKit
import WatchConnectivity
import WidgetKit
import OSLog
import VindsidenWatchKit
import Units

public extension Notification.Name {
    static let ReceivedStations = Notification.Name("ReceivedStations")
}

final class WCFetcher: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let sharedInstance = WCFetcher()

    private var session: WCSession = WCSession.default
    var settings: UserObservable?

    override init() {
        super.init()
        session.delegate = self
    }

    func activate() -> Void {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            Logger.debugging.debug("Session: \(String(describing: self.session))")
        } else {
            Logger.debugging.debug("WCSession is not supported")
        }

        if session.hasContentPending {
            Logger.debugging.debug("application context \(self.session.applicationContext)")
            Logger.debugging.debug("application \(self.session.receivedApplicationContext)")
        } else {
            Logger.debugging.debug("no pending content")
        }
    }

    // MARK: - WCSession

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Logger.debugging.debug("Session: \(session) - \(session.isReachable)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Logger.debugging.debug("Message: \(message)")
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let unit = applicationContext["unit"] as? Int {
            AppConfig.shared.applicationUserDefaults.set(unit, forKey: "selectedUnit")
            AppConfig.shared.applicationUserDefaults.synchronize()
        }

        if let units = applicationContext["units"] as? [String: Int] {
            if let wind = units["windUnit"] {
                Task { @MainActor in
                    self.settings?.windUnit = WindUnit(rawValue: wind)!
                }
            }

            if let temp = units["tempUnit"] {
                Task { @MainActor in
                    settings?.tempUnit = TempUnit(rawValue: temp)!
                }
            }
        }

        if let stations = applicationContext["activeStations"] as? [[String: AnyObject & Sendable]] {
            Task { @MainActor in
                let actor = StationModelActor(modelContainer: PersistentContainer.shared.container)
                _ = await actor.updateWithWatchContent(stations)
                WidgetCenter.shared.invalidateConfigurationRecommendations()
                NotificationCenter.default.post( name: Notification.Name.ReceivedStations, object: nil)
            }
        }

        Logger.debugging.debug("\(applicationContext)")
    }
}
