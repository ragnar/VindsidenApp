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
    let lockQueue = dispatch_queue_create("org.juniks.VindsidenApp.lockQueue", nil)

    class func defaultManager() -> NetworkIndicator {
        struct Singleton {
            static let sharedManager = NetworkIndicator()
        }

        return Singleton.sharedManager
    }


    func startListening() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incrementIndicator:", name: AppConfig.Notification.networkRequestStart, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("decrementIndicator:"), name: AppConfig.Notification.networkRequestEnd, object: nil)
    }


    func stopListening() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    func isNetworkActivityIndicatorVisible() -> Bool {
        return self.numberOfActiveRequests > 0
    }


    func incrementIndicator( notification: NSNotification ) -> Void {
        dispatch_sync(lockQueue) {
            self.numberOfActiveRequests = self.numberOfActiveRequests + 1
            UIApplication.sharedApplication().networkActivityIndicatorVisible = self.isNetworkActivityIndicatorVisible()
        }
    }


    func decrementIndicator( notification: NSNotification ) -> Void {
        dispatch_sync(lockQueue) {
            self.numberOfActiveRequests = max(0, self.numberOfActiveRequests - 1)

            UIApplication.sharedApplication().networkActivityIndicatorVisible = self.isNetworkActivityIndicatorVisible()
        }
    }
}