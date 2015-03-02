//
//  StationDetailsInterfaceController.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 18/11/14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import WatchKit
import VindsidenKit

class StationDetailsInterfaceController: WKInterfaceController {

    @IBOutlet weak var interfaceTable: WKInterfaceTable!
    @IBOutlet weak var windDirectionImage: WKInterfaceImage!
    @IBOutlet weak var windSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var windUnitLabel: WKInterfaceLabel!
    @IBOutlet weak var updatedAtLabel: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject!) {
        super.awakeWithContext(context)

        if let station = context as? CDStation {
            Datamanager.sharedManager().managedObjectContext?.processPendingChanges()
            let oldStaleness = Datamanager.sharedManager().managedObjectContext?.stalenessInterval
            Datamanager.sharedManager().managedObjectContext?.stalenessInterval = 0.0
            Datamanager.sharedManager().managedObjectContext?.refreshObject(station, mergeChanges: false)
            setTitle(station.stationName)
            updateUI(station)
            Datamanager.sharedManager().managedObjectContext?.stalenessInterval = oldStaleness!
        }
    }


    func updateUI( station: CDStation ) -> Void {
        if let plot = station.lastRegisteredPlot() {
            let winddir = CGFloat(plot.windDir.floatValue)
            let windspeed = CGFloat(plot.windAvg.floatValue)
            let image = DrawArrow.drawArrowAtAngle( winddir, forSpeed:windspeed, highlighted:false, color: UIColor.whiteColor(), hightlightedColor: UIColor.blackColor())
            windDirectionImage.setImage(image)
            updatedAtLabel.setText( AppConfig.sharedConfiguration.relativeDate(plot.plotTime))

            let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
            let unit = SpeedConvertion(rawValue: raw)

            if let realUnit = unit {
                windUnitLabel.setText(NSNumber.shortUnitNameString(realUnit))
                windSpeedLabel.setText(convertWindToString(plot.windAvg, toUnit: realUnit))
            }

            updateTableRows(plot)
        }
    }


    func updateTableRows( plot: CDPlot) -> Void {
        let raw = AppConfig.sharedConfiguration.applicationUserDefaults.integerForKey("selectedUnit")
        let unit = SpeedConvertion(rawValue: raw)!

        interfaceTable.setNumberOfRows( 7, withRowType: "stationDetails")

        var index = 0
        var elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Direction")
        elementRow.detailsTextLabel.setText("\(Int(plot.windDir))°")

        index++
        elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Average")
        elementRow.detailsTextLabel.setText(convertWindToString(plot.windAvg, toUnit: unit))

        index++
        elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Gust")
        elementRow.detailsTextLabel.setText(convertWindToString(plot.windMax, toUnit: unit))

        index++
        elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Lull")
        elementRow.detailsTextLabel.setText(convertWindToString(plot.windMin, toUnit: unit))

        index++
        elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Beaufort")
        elementRow.detailsTextLabel.setText("\(Int(plot.windMin.speedInBeaufort()))")

        index++
        elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Air temp")
        elementRow.detailsTextLabel.setText("\(convertNumberToString(plot.tempAir))℃")

        index++
        elementRow = interfaceTable.rowControllerAtIndex(index) as StationDetailsRowController
        elementRow.textLabel.setText("Water temp")
        elementRow.detailsTextLabel.setText("\(convertNumberToString(plot.tempWater))℃")
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

