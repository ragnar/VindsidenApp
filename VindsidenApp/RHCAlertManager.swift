//
//  RHCAlertManager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18/09/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit

@objc(RHCAlertManager)
class RHCAlertManager
{
    var showingError = false
    var networkAlertController: UIAlertController? = nil

    class var defaultManager: RHCAlertManager {
    struct Singleton {
        static let defaultManager = RHCAlertManager()
        }

        return Singleton.defaultManager
    }

    func showNetworkError( error: NSError) -> Void
    {
        if showingError {
            return
        }

        showingError = true

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            var message: NSString? = nil
            let valueOrNil: AnyObject? = error.userInfo?[NSLocalizedDescriptionKey]

            if let value = valueOrNil as? NSString {
                message = value
            }

            if error.domain == (kCFErrorDomainCFNetwork as NSString) || error.domain == NSURLErrorDomain {
                message = NSLocalizedString("NETWORK_ERROR_UNABLE_TO_LOAD", comment: "Unable to fetch data at this point.")
            }

            self.networkAlertController = UIAlertController(title: "", message: message, preferredStyle: .Alert)

            weak var weakAlert = self.networkAlertController

            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction!) -> Void in
                weakAlert?.dismissViewControllerAnimated(true, completion: nil)
                self.showingError = false
            })

            self.networkAlertController?.addAction(defaultAction)

            let appDelegate = UIApplication.sharedApplication().delegate as RHCAppDelegate
            let controller = appDelegate.window.rootViewController

            controller?.presentViewController(self.networkAlertController!, animated: true, completion: nil)
        })
    }
}
