//
//  RHCAlertManager.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18/09/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit

@objc(RHCAlertManager)
class RHCAlertManager : NSObject
{
    var showingError = false
    var networkAlertController: UIAlertController? = nil

    @objc static let defaultManager = RHCAlertManager()

    @objc func showNetworkError( _ error: NSError) -> Void
    {
        if showingError {
            return
        }

        showingError = true

        DispatchQueue.main.async(execute: { () -> Void in
            var message: NSString? = nil
            let valueOrNil: AnyObject? = error.userInfo[NSLocalizedDescriptionKey] as AnyObject?

            if let value = valueOrNil as? NSString {
                message = value
            }

            if error.domain == (kCFErrorDomainCFNetwork as NSString) as String || error.domain == NSURLErrorDomain {
                message = NSLocalizedString("NETWORK_ERROR_UNABLE_TO_LOAD", comment: "Unable to fetch data at this point.") as NSString?
            }

            self.networkAlertController = UIAlertController(title: "", message: message as String?, preferredStyle: UIAlertController.Style.alert)

            weak var weakAlert = self.networkAlertController

            let defaultAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action : UIAlertAction) -> Void in
                weakAlert?.dismiss(animated: true, completion: nil)
                self.showingError = false
            })

            self.networkAlertController?.addAction(defaultAction)

//            let appDelegate = UIApplication.shared.delegate as! RHCAppDelegate
//            let controller = appDelegate.window?.rootViewController
//
//            controller?.present(self.networkAlertController!, animated: true, completion: nil)
        })
    }
}
