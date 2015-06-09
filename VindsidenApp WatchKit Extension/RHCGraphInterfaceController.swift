//
//  RHCGraphInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12.05.15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation


class RHCGraphInterfaceController: WKInterfaceController {

    @IBOutlet weak var graphImage: WKInterfaceImage!
    @IBOutlet weak var stationName: WKInterfaceLabel!


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        if let station = context as? CDStation {
            stationName.setText(station.stationName)

            let bounds = NSStringFromCGRect(WKInterfaceDevice.currentDevice().screenBounds)
            let scale = WKInterfaceDevice.currentDevice().screenScale

            let userInfo = [
                "interface": "graph",
                "action": "update",
                "station": station.stationId,
                "bounds": bounds,
                "scale": scale
                ] as [NSObject:AnyObject]

            WKInterfaceController.openParentApplication( userInfo, reply: { (reply: [NSObject : AnyObject]!, error: NSError!) -> Void in
                DLOG("error: \(error)")

                if let data = reply["graph"] as? NSData {
                    let image = UIImage(data: data, scale:WKInterfaceDevice.currentDevice().screenScale)
                    self.graphImage.setImage(image)
                }
            })
        }
    }


    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }


    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
