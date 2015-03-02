//
//  GlanceController.swift
//  VindsidenApp WatchKit Extension
//
//  Created by Ragnar Henriksen on 18/02/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation
import VindsidenKit


class GlanceController: WKInterfaceController {

    @IBOutlet weak var glanceHeadingLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindCurrentLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindDirectionImage: WKInterfaceImage!


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }


    override func willActivate() {
        super.willActivate()

        if let station = populateStation() {
            self.updateUI(station)

            let userInfo = ["station": station.stationId]
            self.updateUserActivity("AppConfiguration.UserActivity.watch", userInfo: userInfo, webpageURL: nil)

            updatePlotInfo(station)
        }
    }


    override func didDeactivate() {
        super.didDeactivate()
    }


    func populateStation() -> CDStation? {
        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.fetchBatchSize = 1
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        let stations = Datamanager.sharedManager().managedObjectContext?.executeFetchRequest(fetchRequest, error: nil) as [CDStation]

        return stations.first
    }


    func updatePlotInfo( station: CDStation ) {
        RHEVindsidenAPIClient.defaultManager().fetchStationsPlotsForStation(station.stationId, completion: { (success:Bool, plots: [AnyObject]!) -> Void in
            CDPlot.updatePlots(plots, completion: { () -> Void in
                self.updateUI(station)
            })
            }, error: { (cancelled: Bool, error: NSError!) -> Void in
                DLOG("")
        })
    }


    func updateUI(station: CDStation) {
        self.glanceHeadingLabel.setText(station.stationName)

        if let plot = station.lastRegisteredPlot() {
            let winddir = CGFloat(plot.windDir.floatValue)
            let windspeed = CGFloat(plot.windAvg.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())
            self.glanceWindDirectionImage.setImage(image)
            self.glanceWindCurrentLabel.setText("\(plot.windAvg)")
        } else {
            self.glanceWindDirectionImage.setImage(nil)
            self.glanceWindCurrentLabel.setText("–.–")
        }
    }
}
