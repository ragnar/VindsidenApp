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
    @IBOutlet weak var glanceWindDirectionLabel: WKInterfaceLabel!
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
            updateUI(station)
            updatePlotInfo(station)

            let userInfo = [
                "station": station.stationId,
                "urlToActivate": "vindsiden://station/\(station.stationId)"

            ]

            let url = NSURL(string: "http://vindsiden.no/default.aspx?id=\(station.stationId)")

            self.updateUserActivity("org.juniks.VindsidenApp", userInfo: userInfo, webpageURL: url)
        } else {
            updateEmptyUI()
        }

    }


    override func didDeactivate() {
        self.invalidateUserActivity()
        super.didDeactivate()
    }



    // MARK: - Convenience


    func populateStation() -> CDStation? {
        let fetchRequest = NSFetchRequest(entityName: "CDStation")
        fetchRequest.fetchBatchSize = 1
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "isHidden = NO", argumentArray: nil)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        let stations = Datamanager.sharedManager().managedObjectContext?.executeFetchRequest(fetchRequest, error: nil) as! [CDStation]

        return stations.first
    }


    func updatePlotInfo( station: CDStation ) {

        let userInfo = [
            "interface": "glance",
            "action": "update",
            "station": station.stationId
        ]

        WKInterfaceController.openParentApplication( userInfo, reply: { (reply: [NSObject : AnyObject]!, error: NSError!) -> Void in
            if  let station = self.populateStation() {
                self.updateUI(station)
            }
        })
    }


    func updateUI(station: CDStation) {
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!
        let unitString = NSNumber.shortUnitNameString(unit)

        self.glanceHeadingLabel.setText(station.stationName)
        self.glanceHeadingLabel.setTextColor(UIColor.vindsidenGloablTintColor())
        self.glanceWindUnitLabel.setText(unitString)

        if let plot = station.lastRegisteredPlot() {
            let winddir = CGFloat(plot.windDir.floatValue)
            let windspeed = CGFloat(plot.windAvg.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())
            self.glanceWindDirectionImage.setImage(image)
            self.glanceWindDirectionLabel.setText("\(Int(plot.windDir))° (\(plot.windDirectionString()))")
            self.glanceWindCurrentLabel.setText(convertWindToString(plot.windAvg, toUnit: unit))
            self.glanceWindGustLabel.setText("\(convertWindToString(plot.windMax, toUnit: unit)) \(unitString)")
            self.glanceWindLullLabel.setText("\(convertWindToString(plot.windMin, toUnit: unit)) \(unitString)")
            self.glanceWindUpdatedAtLabel.setText( AppConfig.sharedConfiguration.relativeDate(plot.plotTime) as String)
        } else {
            updateEmptyUI()
        }
    }


    func updateEmptyUI() -> Void {
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!
        let unitString = NSNumber.shortUnitNameString(unit)

        self.glanceWindDirectionImage.setImage(nil)
        self.glanceWindDirectionLabel.setText("—° (—)")
        self.glanceWindCurrentLabel.setText("-.-")
        self.glanceWindGustLabel.setText("-.- \(unitString)")
        self.glanceWindLullLabel.setText("-.- \(unitString)")
        self.glanceWindUpdatedAtLabel.setText( NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: NSBundle.mainBundle(), value: "LABEL_NOT_UPDATED", comment: "Not updated"))
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
