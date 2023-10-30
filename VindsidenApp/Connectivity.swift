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

class Connectivity: NSObject, WCSessionDelegate {
    static let shared = Connectivity()

    private var session: WCSession = WCSession.default
    var settings: UserObservable?
    var sendData: Bool = false

    override init() {
        super.init()
        session.delegate = self
    }

    func activate() -> Void {
        Logger.debugging.debug("ACTIVATE")

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
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

#if !os(watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.debugging.debug("did become active")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Logger.debugging.debug("did deactivate")
    }
#endif

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
#if os(iOS)
        if session.isPaired == false || session.isWatchAppInstalled == false {
            Logger.debugging.debug("Watch is not present: \(self.session.isPaired) - \(self.session.isWatchAppInstalled)")
            return
        }
#endif

#if os(watchOS)
        if session.isReachable == false {
            print("Companion app not reachable")
            return
        }
#endif

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

        var context: [String: Any] = [
            "activeStations": stations,
            "units": transferUnits(),
            "unit": AppConfig.sharedConfiguration.applicationUserDefaults.integer(forKey: "selectedUnit"),
        ]

#if os(watchOS)
        context["forcerWatch"] = Date().timeIntervalSince1970
#else
        context["forcerIOS"] = Date().timeIntervalSinceReferenceDate
#endif

        do {
            Logger.debugging.debug("about to send station data \(context)")
            try session.updateApplicationContext(context)
            Logger.debugging.debug("Success: Sent station data")
        } catch {
            Logger.debugging.error("Failed: \(error.localizedDescription)")
        }
    }

    func transferUnits() -> [String: Int] {
        return [
            "windUnit": UserSettings.shared.selectedWindUnit.rawValue,
            "tempUnit": UserSettings.shared.selectedTempUnit.rawValue,
        ]
    }
}
