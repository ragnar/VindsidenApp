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
        NotificationCenter.default.removeObserver(self, name: .ReceivedStations, object: nil)
    }

    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        setTitle("")
        infoLabel.setText(NSLocalizedString("No stations configured", comment: "Not configured header text"))
        infoDetailsLabel.setText(NSLocalizedString("Open the main app to configure visible stations", comment: "Not configured text"))

        NotificationCenter.default.addObserver(self, selector: #selector(receivedStations(_:)), name: .ReceivedStations, object: nil)
    }


    @objc func receivedStations( _ notification: Notification) -> Void {
        let count = CDStation.numberOfVisibleStationsInManagedObjectContext(DataManager.shared.viewContext())

        if count > 0 {
            dismiss()
        }
    }
}
