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


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        if let station = context as? CDStation {
            stationName.setText(station.stationName)

            guard let stationId = station.stationId else {
                DLOG("Missing stationId")
                return;
            }

            let screenScale = WKInterfaceDevice.current().screenScale
            let imageData = generateGraphImage(stationId.intValue, screenSize: WKInterfaceDevice.current().screenBounds, scale: screenScale)
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



    func generateGraphImage( _ stationId: Int, screenSize: CGRect, scale: CGFloat ) -> Data {
        let graphImage: GraphImage
        let imageSize = CGSize( width: screenSize.width, height: screenSize.height - 40.0)
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let inDate = Date().addingTimeInterval(-1*4*3600)
        let inputComponents = (gregorian as NSCalendar).components([.year, .month, .day, .hour], from: inDate)
        let outDate = gregorian.date(from: inputComponents)!

        let fetchRequest = CDPlot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "station.stationId = %ld AND plotTime >= %@", stationId, outDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "plotTime", ascending: false)]

        do {
            let result = try DataManager.shared.viewContext().fetch(fetchRequest) as! [CDPlot]
            graphImage = GraphImage(size: imageSize, scale: scale, plots: result)
        } catch {
            graphImage = GraphImage(size: imageSize, scale: scale)
        }

        let image = graphImage.drawImage()
        return UIImagePNGRepresentation(image)!
    }
}
