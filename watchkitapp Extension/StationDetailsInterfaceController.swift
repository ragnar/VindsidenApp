//
//  StationDetailsInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18/11/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import WatchKit
import VindsidenWatchKit

class StationDetailsInterfaceController: WKInterfaceController {

    @IBOutlet weak var interfaceTable: WKInterfaceTable!
    @IBOutlet weak var windDirectionImage: WKInterfaceImage!
    @IBOutlet weak var windDirectionLabel: WKInterfaceLabel!
    @IBOutlet weak var windSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var windUnitLabel: WKInterfaceLabel!
    @IBOutlet weak var updatedAtLabel: WKInterfaceLabel!

    @IBOutlet weak var windGustLabel: WKInterfaceLabel!
    @IBOutlet weak var windLull: WKInterfaceLabel!
    @IBOutlet weak var windBeaufortLabel: WKInterfaceLabel!
    @IBOutlet weak var airTempLabel: WKInterfaceLabel!

    var station: CDStation?

    override func awakeWithContext(context: AnyObject!) {
        super.awakeWithContext(context)

        if let station = context as? CDStation {

            self.station = station

            Datamanager.sharedManager().managedObjectContext.processPendingChanges()
            let oldStaleness = Datamanager.sharedManager().managedObjectContext.stalenessInterval
            Datamanager.sharedManager().managedObjectContext.stalenessInterval = 0.0
            Datamanager.sharedManager().managedObjectContext.refreshObject(station, mergeChanges: false)
            setTitle(station.stationName)
            updateUI(station)
            Datamanager.sharedManager().managedObjectContext.stalenessInterval = oldStaleness
            let stationId = station.stationId! as Int
            let userInfo = [
                "station": stationId,
                "urlToActivate": "vindsiden://station/\(stationId)"

            ] as [String:AnyObject]

            let url = NSURL(string: "http://vindsiden.no/default.aspx?id=\(stationId)")

            self.updateUserActivity("org.juniks.VindsidenApp", userInfo: userInfo, webpageURL: url)
        }
    }


    override func didDeactivate() {
        self.invalidateUserActivity()
        super.didDeactivate()
    }


    // MARK: - Actions


    @IBAction func graphButtonPressed() {
        presentControllerWithName("graph", context: station)
    }


    @IBAction func mapButtonPressed() {
        presentControllerWithName("showMap", context: station)
    }


    // MARK: - Convenience


    func updateUI( station: CDStation ) -> Void {
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)

        if let realUnit = unit {
            windUnitLabel.setText(NSNumber.shortUnitNameString(realUnit))
        }

        if let plot = station.lastRegisteredPlot() {

            let winddir = CGFloat(plot.windDir!.floatValue)
            let windspeed = CGFloat(plot.windAvg!.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())
            windDirectionImage.setImage(image)
            updatedAtLabel.setText( AppConfig.sharedConfiguration.relativeDate(plot.plotTime!) as String)

            if let realUnit = unit {
                let unitString = NSNumber.shortUnitNameString(realUnit)

                windSpeedLabel.setText(convertWindToString(plot.windAvg!, toUnit: realUnit))
                windDirectionLabel.setText("\(Int(plot.windDir!))° (\(plot.windDirectionString()))")
                windGustLabel.setText("\(convertWindToString(plot.windMax!, toUnit: realUnit)) \(unitString)")
                windLull.setText("\(convertWindToString(plot.windMin!, toUnit: realUnit)) \(unitString)")
                windBeaufortLabel.setText("\(Int(plot.windMin!.speedInBeaufort()))")
                airTempLabel.setText("\(convertNumberToString(plot.tempAir!))℃")
            }
        } else {
            if let realUnit = unit {
                let unitString = NSNumber.shortUnitNameString(realUnit)

                windDirectionImage.setImage(nil)
                windDirectionLabel.setText("—° (—)")
                windSpeedLabel.setText("–.–")
                windGustLabel.setText("-.- \(unitString)")
                windLull.setText("-.- \(unitString)")
                windBeaufortLabel.setText("-")
                airTempLabel.setText("-.-℃")
                updatedAtLabel.setText( NSLocalizedString("LABEL_NOT_UPDATED", tableName: nil, bundle: NSBundle.mainBundle(), value: "LABEL_NOT_UPDATED", comment: "Not updated"))
            }
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
