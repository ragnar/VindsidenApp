//
//  Connectivity.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 25/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WatchConnectivity
import OSLog
import VindsidenKit

final class Connectivity: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = Connectivity()

    private var session: WCSession = WCSession.default
    var settings: UserObservable?
    var sendData: Bool = false

    override init() {
        super.init()
        session.delegate = self
    }

    func activate() -> Void {
        guard WCSession.isSupported() else {
            Logger.debugging.debug("WCSession is not supported")
            return
        }

        session.delegate = self
        session.activate()

        if session.hasContentPending {
            Logger.debugging.debug("application context \(self.session.applicationContext)")
            Logger.debugging.debug("application \(self.session.receivedApplicationContext)")
        } else {
            Logger.debugging.debug("no pending content")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.debugging.debug("did become active")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.debugging.debug("did deactivate")
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Logger.debugging.debug("activation")

        if activationState == .activated {
            Logger.debugging.debug("active")
        }

        if activationState == .activated, sendData {
            Task {
                await updateApplicationContextToWatch()
            }
            sendData = false
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Logger.debugging.debug("did receive \(applicationContext)")

        guard let settings = settings else {
            fatalError("Need settings")
        }

        settings.updateFromApplicationContext(applicationContext)
    }

    @MainActor
    func updateApplicationContextToWatch() {
        if session.isPaired == false || session.isWatchAppInstalled == false {
            Logger.debugging.debug("Watch is not present: \(self.session.isPaired) - \(self.session.isWatchAppInstalled)")
            return
        }

        if session.activationState != .activated {
            sendData = true
            activate()
            return
        }

        let result = Station.visible(in: PersistentContainer.shared.container.mainContext)
        var stations = [[String: Any]]()

        result.forEach { station in
            stations.append([
                "stationId": station.stationId as Any,
                "stationName": station.stationName as Any,
                "order": station.order as Any,
                "hidden": station.isHidden as Any,
                "latitude": station.coordinateLat as Any,
                "longitude": station.coordinateLon as Any,
            ])
        }

        let context: [String: Any] = [
            "activeStations": stations,
            "units": transferUnits(),
            "unit": AppConfig.shared.applicationUserDefaults.integer(forKey: "selectedUnit"),
            "forcerIOS": Date.now.timeIntervalSinceReferenceDate,
        ]

        do {
            Logger.debugging.debug("about to send station data \(context)")
            try session.updateApplicationContext(context)
            Logger.debugging.debug("Success: Sent station data")
        } catch {
            Logger.debugging.error("Failed: \(error.localizedDescription)")
        }
    }

    func transferUnits() -> [String: Int] {
        guard let settings = settings else {
            fatalError("Need settings")
        }

        return [
            "windUnit": settings.windUnit.rawValue,
            "tempUnit": settings.tempUnit.rawValue,
        ]
    }
}
