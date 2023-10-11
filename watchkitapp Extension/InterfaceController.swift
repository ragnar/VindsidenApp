//
//  InterfaceController.swift
//  VindsidenApp WatchKit Extension
//
//  Created by Ragnar Henriksen on 18/02/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import WatchKit
import Foundation
import VindsidenWatchKit
import CoreData
import OSLog

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var interfaceTable: WKInterfaceTable!

    var stations = [CDStation]()
    var fetchingPlots = false


    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.ReceivedStations, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.ReceivedPlots, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FetchingPlots, object: nil)
    }

    
    override func awake(withContext context: Any!) {
        super.awake(withContext: context)
        stations = populateData()

        NotificationCenter.default.addObserver(self, selector: #selector(InterfaceController.receivedStations(_:)), name: NSNotification.Name.ReceivedStations, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(InterfaceController.receivedStations(_:)), name: NSNotification.Name.ReceivedPlots, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(InterfaceController.updatingPlots(_:)), name: NSNotification.Name.FetchingPlots, object: nil)
    }


    override func willActivate() {
        super.willActivate()
        stations = populateData()
        loadTableData()

        if stations.count == 0 {
            presentController(withName: "notConfigured", context: nil)
        }
    }


    override func didDeactivate() {
        super.didDeactivate()
    }


    @IBAction func settingsButtonPressed() {
        presentController(withName: "stationConfig", context: nil)
    }


    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        pushController(withName: "stationDetails", context: stations[rowIndex])
    }


    @objc func receivedStations( _ notification: Notification) -> Void {
        if fetchingPlots && notification.name == .ReceivedPlots {
            fetchingPlots = false
        }
        configureView()
    }


    @objc func updatingPlots( _ notification: Notification) -> Void {
        fetchingPlots = true
        configureView()
    }


    func configureView() {
        stations = populateData()
        loadTableData()

        if stations.count == 0 {
            presentController(withName: "notConfigured", context: nil)
        }
    }


    func populateData() -> [CDStation] {
        let fetchRequest: NSFetchRequest<CDStation> = CDStation.fetchRequest()
        fetchRequest.fetchBatchSize = 3
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        do {
            let stations = try DataManager.shared.viewContext().fetch(fetchRequest)
            return stations
        } catch {
            return []
        }
    }


    func loadTableData() -> Void {
        interfaceTable.setNumberOfRows(stations.count, withRowType: "default")

        for (index, station) in stations.enumerated() {
            DataManager.shared.viewContext().refresh(station, mergeChanges: true)

            let elementRow = interfaceTable.rowController(at: index) as! StationsRowController
            elementRow.elementText.setText(station.stationName)

            if let plot = station.lastRegisteredPlot() {
                let winddir = CGFloat(plot.windDir!.floatValue)
                let windspeed = CGFloat(plot.windAvg!.floatValue)
                let image = DrawArrow.drawArrow( atAngle: winddir, forSpeed:windspeed, highlighted:false, color: UIColor.white, hightlightedColor: UIColor.black)
                elementRow.elementImage.setImage(image)
                elementRow.elementUpdated.setText( AppConfig.sharedConfiguration.relativeDate(plot.plotTime!) as String)
            } else {
                elementRow.elementUpdated.setText( NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: Bundle.main, value: "LABEL_NOT_UPDATED", comment: "Not updated"))
            }

            if fetchingPlots {
                elementRow.elementUpdated.setText( NSLocalizedString("Updating", tableName: nil, bundle: Bundle.main, value: "Updating", comment: "Updating"))
            }
        }
    }


    override func handleUserActivity(_ userInfo: [AnyHashable: Any]!) {
        let stationId = userInfo?["station"] as? NSNumber
        if stationId == nil {
            Logger.debugging.debug("No station provided")
            return
        }

        stations = populateData()

        for station in stations {
            if station.stationId!.isEqual(to: stationId!) {
                pushController(withName: "stationDetails", context: station)
                break
            }
        }
    }
}
