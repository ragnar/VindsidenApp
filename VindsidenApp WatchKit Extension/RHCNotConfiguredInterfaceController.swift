//
//  RHCNotConfiguredInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 23/04/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation
import VindsidenWatchKit


class RHCNotConfiguredInterfaceController: WKInterfaceController {

    @IBOutlet weak var infoLabel: WKInterfaceLabel!
    @IBOutlet weak var infoDetailsLabel: WKInterfaceLabel!


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: WCFetcherNotification.ReceivedStations, object: nil)
    }

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        setTitle("")
        infoLabel.setText(NSLocalizedString("No stations configured", comment: "Not configured header text"))
        infoDetailsLabel.setText(NSLocalizedString("Open the main app to configure visible stations", comment: "Not configured text"))

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RHCNotConfiguredInterfaceController.receivedStations(_:)), name: WCFetcherNotification.ReceivedStations, object: nil)
    }


    func receivedStations( notification: NSNotification) -> Void {
        let count = CDStation.numberOfVisibleStationsInManagedObjectContext(Datamanager.sharedManager().managedObjectContext)

        if count > 0 {
            dismissController()
        }
    }
}
