//
//  RHCGraphInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12.05.15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation
import CoreData
import VindsidenWatchKit

class RHCGraphInterfaceController: WKInterfaceController {

    @IBOutlet weak var graphImage: WKInterfaceImage!
    @IBOutlet weak var stationName: WKInterfaceLabel!


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        if let station = context as? CDStation {
            stationName.setText(station.stationName)

            guard let stationId = station.stationId else {
                DLOG("Missing stationId")
                return;
            }

            let screenScale = WKInterfaceDevice.currentDevice().screenScale
            let imageData = generateGraphImage(stationId.integerValue, screenSize: WKInterfaceDevice.currentDevice().screenBounds, scale: screenScale)
            let image = UIImage(data: imageData, scale: screenScale)
            graphImage.setImage(image)
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



    func generateGraphImage( stationId: Int, screenSize: CGRect, scale: CGFloat ) -> NSData {
        let graphImage: GraphImage
        let imageSize = CGSizeMake( CGRectGetWidth(screenSize), CGRectGetHeight(screenSize) - 40.0)

        if let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
            let inDate = NSDate().dateByAddingTimeInterval(-1*4*3600)
            let inputComponents = gregorian.components([.Year, .Month, .Day, .Hour], fromDate: inDate)
            let outDate = gregorian.dateFromComponents(inputComponents)!

            let fetchRequest = NSFetchRequest(entityName: "CDPlot")
            fetchRequest.predicate = NSPredicate(format: "station.stationId = %ld AND plotTime >= %@", stationId, outDate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "plotTime", ascending: false)]

            do {
                let result = try Datamanager.sharedManager().managedObjectContext.executeFetchRequest(fetchRequest) as! [CDPlot]
                graphImage = GraphImage(size: imageSize, scale: scale, plots: result)
            } catch {
                graphImage = GraphImage(size: imageSize, scale: scale)
            }
        } else {
            graphImage = GraphImage(size: imageSize, scale: scale)
        }

        let image = graphImage.drawImage()
        return UIImagePNGRepresentation(image)!
    }
}
