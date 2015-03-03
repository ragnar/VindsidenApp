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

    @IBOutlet weak var glanceWindDirectionImage: WKInterfaceImage!
    @IBOutlet weak var glanceHeadingLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindCurrentLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindGustLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindLullLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindUpdatedAtLabel: WKInterfaceLabel!
    @IBOutlet weak var glanceWindUnitLabel: WKInterfaceLabel!


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
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!
        let unitString = NSNumber.shortUnitNameString(unit)

        self.glanceHeadingLabel.setText(station.stationName)
        self.glanceWindUnitLabel.setText(unitString)

        if let plot = station.lastRegisteredPlot() {
            let winddir = CGFloat(plot.windDir.floatValue)
            let windspeed = CGFloat(plot.windAvg.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())
            self.glanceWindDirectionImage.setImage(image)
            self.glanceWindCurrentLabel.setText(convertWindToString(plot.windAvg, toUnit: unit))
            self.glanceWindGustLabel.setText("Gust: \(convertWindToString(plot.windMax, toUnit: unit)) \(unitString)")
            self.glanceWindLullLabel.setText("Lull: \(convertWindToString(plot.windMin, toUnit: unit)) \(unitString)")
            self.glanceWindUpdatedAtLabel.setText( AppConfig.sharedConfiguration.relativeDate(plot.plotTime))
        } else {
            self.glanceWindDirectionImage.setImage(nil)
            self.glanceWindCurrentLabel.setText("–.–")
            self.glanceWindGustLabel.setText("G: -.- \(unitString)")
            self.glanceWindLullLabel.setText("L: -.- \(unitString)")
            self.glanceWindUpdatedAtLabel.setText( NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: NSBundle.mainBundle(), value: "LABEL_NOT_UPDATED", comment: "Not updated"))
        }
    }

    func convertWindToString( wind: NSNumber, toUnit unit: SpeedConvertion) -> String {
        if let speedString = speedFormatter.stringFromNumber(wind.speedConvertionTo(unit)) {
            return speedString
        } else {
            return "—.—"
        }
    }

    func convertNumberToString( number: NSNumber) -> String {
        if let numberString = speedFormatter.stringFromNumber(number) {
            return numberString
        } else {
            return "—.—"
        }
    }

    lazy var speedFormatter : NSNumberFormatter = {
        let _speedFormatter = NSNumberFormatter()
        _speedFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        _speedFormatter.maximumFractionDigits = 1
        _speedFormatter.minimumFractionDigits = 1
        _speedFormatter.notANumberSymbol = "—.—"
        _speedFormatter.nilSymbol = "—.—"

        return _speedFormatter
        }()

}
