//
//  RHCNotConfiguredInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 23/04/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation


class RHCNotConfiguredInterfaceController: WKInterfaceController {

    @IBOutlet weak var infoLabel: WKInterfaceLabel!
    @IBOutlet weak var infoDetailsLabel: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        setTitle("Vindsiden")
        infoLabel.setText(NSLocalizedString("No stations configured", comment: "Not configured header text"))
        infoDetailsLabel.setText(NSLocalizedString("Open the main app to configure visible stations", comment: "Not configured text"))
    }
}
