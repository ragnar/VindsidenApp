//
//  NetworkIndicator.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 06.09.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation


@objc
class NetworkIndicator : NSObject {

    var numberOfActiveRequests = 0
    let lockQueue = DispatchQueue(label: "org.juniks.VindsidenApp.lockQueue", attributes: [])

    class func defaultManager() -> NetworkIndicator {
        struct Singleton {
            static let sharedManager = NetworkIndicator()
        }

        return Singleton.sharedManager
    }


    func startListening() {
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkIndicator.incrementIndicator(_:)), name: AppConfig.Notifications.networkRequestStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkIndicator.decrementIndicator(_:)), name: AppConfig.Notifications.networkRequestEnd, object: nil)
    }


    func stopListening() {
        NotificationCenter.default.removeObserver(self)
    }


    func isNetworkActivityIndicatorVisible() -> Bool {
        return self.numberOfActiveRequests > 0
    }


    @objc func incrementIndicator( _ notification: Notification ) -> Void {
        lockQueue.sync {
            self.numberOfActiveRequests = self.numberOfActiveRequests + 1

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.isNetworkActivityIndicatorVisible()
            }
        }
    }


    @objc func decrementIndicator( _ notification: Notification ) -> Void {
        lockQueue.sync {
            self.numberOfActiveRequests = max(0, self.numberOfActiveRequests - 1)

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.isNetworkActivityIndicatorVisible()
            }
        }
    }
}
