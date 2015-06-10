//
//  InterfaceController.swift
//  VindsidenApp WatchKit Extension
//
//  Created by Ragnar Henriksen on 18/02/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation
import VindsidenKit


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var interfaceTable: WKInterfaceTable!

    var stations = [CDStation]()

    override func awakeWithContext(context: AnyObject!) {
        super.awakeWithContext(context)
        fetchContent()
    }


    override func willActivate() {
        super.willActivate()
        stations = populateData()

        if stations.count == 0 {
            pushControllerWithName("notConfigured", context: nil)
        } else {
            loadTableData()
        }
    }


    override func didDeactivate() {
        super.didDeactivate()
    }


    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        pushControllerWithName("stationDetails", context: stations[rowIndex])
    }


    func populateData() -> [CDStation] {
        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.fetchBatchSize = 3
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        do {
            let stations = try Datamanager.sharedManager().managedObjectContext?.executeFetchRequest(fetchRequest) as! [CDStation]
            return stations
        } catch {
            return [CDStation]()
        }
    }


    func loadTableData() -> Void {
        interfaceTable.setNumberOfRows(stations.count, withRowType: "default")

        for (index, station) in stations.enumerate() {
            Datamanager.sharedManager().managedObjectContext?.refreshObject(station, mergeChanges: true)

            let elementRow = interfaceTable.rowControllerAtIndex(index) as! StationsRowController
            elementRow.elementText.setText(station.stationName)

            if let plot = station.lastRegisteredPlot() {
                let winddir = CGFloat(plot.windDir.floatValue)
                let windspeed = CGFloat(plot.windAvg.floatValue)
                let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())
                elementRow.elementImage.setImage(image)
                elementRow.elementUpdated.setText( AppConfig.sharedConfiguration.relativeDate(plot.plotTime) as String)
            } else {
                elementRow.elementUpdated.setText( NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: NSBundle.mainBundle(), value: "LABEL_NOT_UPDATED", comment: "Not updated"))
            }
        }
    }


    func fetchContent() -> Void {
        let userInfo = [
            "interface": "main",
            "action": "update",
        ]

        WKInterfaceController.openParentApplication( userInfo, reply: { (reply: [NSObject : AnyObject], error: NSError?) -> Void in
            self.stations = self.populateData()

            if self.stations.count == 0 {
                self.pushControllerWithName("notConfigured", context: nil)
            } else {
                self.loadTableData()
            }
        })
    }


    override func handleUserActivity(userInfo: [NSObject : AnyObject]!) {
        let stationId = userInfo?["station"] as? NSNumber
        if stationId == nil {
            DLOG("No station provided")
            return
        }

        stations = populateData()

        for station in stations {
            if station.stationId.isEqualToNumber(stationId!) {
                pushControllerWithName("stationDetails", context: station)
                break
            }
        }
    }
}
