//
//  MapInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27.08.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation
import VindsidenWatchKit


class MapInterfaceController: WKInterfaceController {

    @IBOutlet var mapInterface: WKInterfaceMap!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if let station = context as? CDStation {
            setTitle(station.stationName)


            let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)

            mapInterface.setVisibleMapRect(MKMapRect(origin: MKMapPointForCoordinate(station.coordinate), size: MKMapSize(width: 0.5, height: 0.5)))
            mapInterface.setRegion(MKCoordinateRegion(center: station.coordinate, span: coordinateSpan))
            mapInterface.addAnnotation(station.coordinate, withPinColor: .Red)
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
