//
//  CDPlot.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation
import CoreData
import OSLog

@objc(CDPlot)
open class CDPlot: NSManagedObject {


    open class func newOrExistingPlot( _ content: [String:String], forStation station:CDStation, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> CDPlot {
        if let unwrapped = content["DataID"], let dataId = Int(unwrapped) {
            let request: NSFetchRequest<CDPlot> = CDPlot.fetchRequest()
            request.predicate = NSPredicate(format: "dataId == %@ and station == %@", argumentArray: [dataId, station])
            request.fetchLimit = 1

            do {
                let result = try managedObjectContext.fetch(request)
                if let plot = result.first {
                    return plot
                }
            } catch {
            }
        }

        let entity = CDPlot.entity()
        let plot = CDPlot(entity: entity, insertInto: managedObjectContext)

        plot.updateWithContent(content)

        return plot
    }


    open class func updatePlots(_ plots: [[String: String]]) throws {
        if plots.isEmpty {
            return
        }

        guard
            let plot = plots.first,
            let stationString = plot["StationID"],
            let stationId = Int(stationString)
        else {
            return
        }

        let context = DataManager.shared.container.newBackgroundContext()

        context.mergePolicy = NSOverwriteMergePolicy

        let station = try CDStation.existingStationWithId(stationId, inManagedObjectContext: context)
        let insertedPlots = NSMutableSet()

        for plot in plots {
            let managedObject = CDPlot.newOrExistingPlot(plot, forStation: station, inManagedObjectContext: context)

            if managedObject.isInserted {
                insertedPlots.add(managedObject)
            }
        }

        if insertedPlots.count > 0 {
            station.willChangeValue(forKey: "plots")
            station.addToPlots(insertedPlots)
            station.didChangeValue(forKey: "plots")
        }

        try context.save()
    }

    func updateWithContent( _ content: [String:String] ) {
        if let unwrapped = content["Time"] {
            self.plotTime = DataManager.shared.dateFromString(unwrapped)
        }

        if let unwrapped = content["WindAvg"], let avg = Double(unwrapped) {
            self.windAvg = avg as NSNumber?
        }

        if let unwrapped = content["WindMax"], let max = Double(unwrapped) {
            self.windMax = max as NSNumber?
        }

        if let unwrapped = content["WindMin"], let min = Double(unwrapped) {
            self.windMin = min as NSNumber?
        }

        if let unwrapped = content["DirectionAvg"], let dir = Double(unwrapped) {
            self.windDir = dir as NSNumber?
        }

        if let unwrapped = content["Temperature1"], let temp = Double(unwrapped) {
            self.tempAir = temp as NSNumber?
        }

        if let unwrapped = content["DataID"], let dataId = Int(unwrapped) {
            self.dataId = dataId as NSNumber?
        }
    }


    @objc open func windDirectionString() -> String {
        let bundle = AppConfig.sharedConfiguration.frameworkBundle
        var direction = self.windDir!.floatValue

        if direction > 360.0 || direction < 0.0 {
            direction = 0.0;
        }

        switch(direction) {
        case 0...11.25, 347.75...360.0:
            return NSLocalizedString("DIRECTION_N", bundle: bundle, comment: "WindPlot, Wind direction: N")
        case 11.25...33.35:
            return NSLocalizedString("DIRECTION_NNE", bundle: bundle, comment: "WindPlot, Wind direction: NNE")
        case 33.75...56.25:
            return NSLocalizedString("DIRECTION_NE", bundle: bundle, comment: "WindPlot, Wind direction: NE")
        case 56.25...78.75:
            return NSLocalizedString("DIRECTION_ENE", bundle: bundle, comment: "WindPlot, Wind direction: ENE")
        case 78.75...101.25:
            return NSLocalizedString("DIRECTION_E", bundle: bundle, comment: "WindPlot, Wind direction: E")
        case 101.25...123.75:
            return NSLocalizedString("DIRECTION_ESE", bundle: bundle, comment: "WindPlot, Wind direction: ESE")
        case 123.75...146.25:
            return NSLocalizedString("DIRECTION_SE", bundle: bundle, comment: "WindPlot, Wind direction: SE")
        case 146.25...168.75:
            return NSLocalizedString("DIRECTION_SSE", bundle: bundle, comment: "WindPlot, Wind direction: SSE")
        case 168.75...191.25:
            return NSLocalizedString("DIRECTION_S", bundle: bundle, comment: "WindPlot, Wind direction: S")
        case 191.25...213.75:
            return NSLocalizedString("DIRECTION_SSW", bundle: bundle, comment: "WindPlot, Wind direction: SSW")
        case 213.75...236.25:
            return NSLocalizedString("DIRECTION_SW", bundle: bundle, comment: "WindPlot, Wind direction: SW")
        case 236.25...258.75:
            return NSLocalizedString("DIRECTION_WSW", bundle: bundle, comment: "WindPlot, Wind direction: WSW")
        case 258.75...281.25:
            return NSLocalizedString("DIRECTION_W", bundle: bundle, comment: "WindPlot, Wind direction: W")
        case 281.25...303.75:
            return NSLocalizedString("DIRECTION_WNW", bundle: bundle, comment: "WindPlot, Wind direction: WNW")
        case 303.75...326.25:
            return NSLocalizedString("DIRECTION_NW", bundle: bundle, comment: "WindPlot, Wind direction: NW")
        case 326.25...348.75:
            return NSLocalizedString("DIRECTION_NNW", bundle: bundle, comment: "WindPlot, Wind direction: NNW")
        default:
            return NSLocalizedString("DIRECTION_UKN", bundle: bundle, comment: "WindPlot, Wind direction: UKN")
        }
    }
}
