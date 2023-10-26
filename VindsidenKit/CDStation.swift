//
//  CDStation.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15.06.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import OSLog

@objc(CDStation)
public class CDStation: NSManagedObject, MKAnnotation {

    // MARK: - MKAnnotation

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: (self.coordinateLat?.doubleValue)!, longitude: (self.coordinateLon?.doubleValue)!)
    }

    public var title: String? {
        return self.stationName
    }

    public var subtitle: String? {
        return self.city
    }

    @objc
    public class func existingStationWithId(_ stationId:Int, inManagedObjectContext managedObjectContext: NSManagedObjectContext) throws -> CDStation {
        let request: NSFetchRequest<CDStation> = CDStation.fetchRequest()
        request.predicate = NSPredicate(format: "stationId == \(stationId)")
        request.fetchLimit = 1

        let result = try managedObjectContext.fetch(request)

        if let first = result.first {
            return first
        }

        throw NSError(domain: AppConfig.Bundle.appName, code: -1, userInfo: nil)
    }

    public class func newOrExistingStationWithId(_ stationId: Int, inManagedObectContext managedObjectContext: NSManagedObjectContext) -> CDStation {
        do {
            return try CDStation.existingStationWithId(stationId, inManagedObjectContext: managedObjectContext)
        } catch {
            let entity = CDStation.entity()
            let station = CDStation(entity: entity, insertInto: managedObjectContext)
            return station
        }
    }

    public class func searchForStationName(_ stationName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> CDStation? {
        let request: NSFetchRequest<CDStation> = CDStation.fetchRequest()
        request.predicate = NSPredicate(format: "stationName contains[cd] %@", argumentArray: [stationName])
        request.fetchLimit = 1

        do {
            let result = try managedObjectContext.fetch(request)
            if let first = result.first {
                return first
            }
        } catch {
            return nil
        }

        return nil
    }

    public class func maxOrderForStationsInManagedObjectContext(_ managedObjectContext: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<NSFetchRequestResult> = CDStation.fetchRequest()
        request.fetchLimit = 1

        let expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "order")])
        let expressionDescription = NSExpressionDescription()
        expressionDescription.expression = expression
        expressionDescription.expressionResultType = .integer16AttributeType
        expressionDescription.name = "nextNumber"

        request.propertiesToFetch = [expressionDescription]
        request.resultType = .dictionaryResultType

        do {
            let result = try managedObjectContext.fetch(request)
            if let first = result.first as? [String:Any], let max = first["nextNumber"] as? Int {
                return max
            }
        } catch {
            return 0
        }

        return 0
    }

    @objc
    public class func numberOfVisibleStationsInManagedObjectContext(_ managedObjectContext: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<CDStation> = CDStation.fetchRequest()
        request.predicate = NSPredicate(format: "isHidden == NO")

        do {
            return try managedObjectContext.count(for: request)
        } catch {
            return 0
        }
    }

    @objc
    public class func visibleStationsInManagedObjectContext(_ managedObjectContext: NSManagedObjectContext, limit: Int = 0) -> [CDStation] {
        let request: NSFetchRequest<CDStation> = CDStation.fetchRequest()
        request.fetchBatchSize = 20
        request.predicate = NSPredicate(format: "isHidden == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        if limit > 0 {
            request.fetchLimit = limit
        }

        do {
            return try managedObjectContext.fetch(request)
        } catch {
            return []
        }
    }

    @objc
    public func lastRegisteredPlot() -> CDPlot? {
        let inDate = Date().addingTimeInterval(-1*AppConfig.Global.plotHistory*3600)
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let inputComponents = (gregorian as NSCalendar).components([.year, .month, .day, .hour], from: inDate)

        guard let outDate = gregorian.date(from: inputComponents) else {
            Logger.persistence.debug("Outdate missing")
            return nil
        }

        let request: NSFetchRequest<CDPlot> = CDPlot.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "station == %@ AND plotTime >= %@", argumentArray: [self, outDate] )
        request.sortDescriptors = [NSSortDescriptor(key: "plotTime", ascending: false)]

        do {
            let result = try self.managedObjectContext!.fetch(request)
            if let first = result.first {
                return first
            }
        } catch {
            return nil
        }

        return nil
    }

    @objc
    public class func updateWithFetchedContent(_ content: [[String:String]], inManagedObjectContext managedObjectContext: NSManagedObjectContext, completionHandler: ((Bool) -> Void)? = nil) {
        if content.count == 0 {
            completionHandler?(false)
            return
        }

        DataManager.shared.performBackgroundTask { (context) in
            var order = CDStation.maxOrderForStationsInManagedObjectContext(context)
            var newStations = false

            if order == 0 {
                order = 200
            }

            let stationIds = content.map { return Int($0["StationID"]!)! }
            CDStation.removeStaleStations(stationIds, inManagedObjectContext: context)

            for stationContent in content {
                guard let stationIdString = stationContent["StationID"] else {
                    Logger.persistence.debug("No stationId")
                    continue
                }

                let stationId = Int(stationIdString)!
                let station = CDStation.newOrExistingStationWithId(stationId, inManagedObectContext: context)
                station.updateWithContent(stationContent)

                if station.isInserted {
                    newStations = true

                    if station.stationId == 60 {
                        station.order = 101
                        station.isHidden = false
                        #if os(iOS)
                            DataManager.shared.addStationToIndex(station)
                        #endif
                    } else {
                        order += 1
                        station.order = order as NSNumber?
                        station.isHidden = true
                    }
                }
            }


            do {
                try context.save()
                DispatchQueue.main.async {
                    completionHandler?(newStations)
                }
                return
            } catch let error as NSError {
                Logger.persistence.debug("Error: \(error.userInfo.keys)")
                DispatchQueue.main.async {
                    completionHandler?(newStations)
                }
                return
            } catch {
                Logger.persistence.debug("Error: \(error)")
                DispatchQueue.main.async {
                    completionHandler?(newStations)
                }
                return
            }
        }
    }

    public class func updateWithWatchContent(_ content: [[String:AnyObject]]) async -> Bool {
        return await DataManager.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSOverwriteMergePolicy

            let stationIds: [Int] = content.map { return $0["stationId"] as! Int }
            CDStation.removeStaleStations(stationIds, inManagedObjectContext: context)

            for stationContent in content {
                guard let stationId = stationContent["stationId"] as? Int else {
                    Logger.persistence.debug("No stationId")
                    continue
                }

                let station = CDStation.newOrExistingStationWithId(stationId, inManagedObectContext: context)
                station.updateWithWatchContent(stationContent)
            }

            do {
                try context.save()

                return false
            } catch let error as NSError {
                Logger.persistence.debug("Error: \(error.userInfo.keys)")
                return false
            } catch {
                Logger.persistence.debug("Error: \(error)")
                return false
            }
        }
    }

    public class func removeStaleStations(_ stations: [Int], inManagedObjectContext context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDStation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "NOT stationId IN (%@)", stations)

        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        request.resultType = .resultTypeCount

        do {
            let result = try context.execute(request) as! NSBatchDeleteResult
            Logger.persistence.debug("Deleted \(result.result as? Int ?? -1) station(s)")
        } catch {
            Logger.persistence.debug("Delete failed: \(error)")
        }
    }

    func updateWithContent(_ content: [String:String] ) {
        if let unwrapped = content["StationID"], let stationId = Int(unwrapped) {
            self.stationId = stationId as NSNumber?
        }

        if let name = content["Name"] {
            self.stationName = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let text = content["Text"] {
            self.stationText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let city = content["City"] {
            self.city = city.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let copyright = content["Copyright"] {
            self.copyright = copyright.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let statusMessage = content["StatusMessage"] {
            self.statusMessage = statusMessage.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let coordinate = content["Latitude"], let lat = Double(coordinate) {
            self.coordinateLat = lat as NSNumber?
        }

        if let coordinate = content["Longitude"], let lng = Double(coordinate) {
            self.coordinateLon = lng as NSNumber?
        }

        if let yrURL = content["MeteogramUrl"] {
            self.yrURL = yrURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let webCamImage = content["WebcamImage"] {
            self.webCamImage = webCamImage.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let webCamText = content["WebcamText"] {
            self.webCamText = webCamText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let webCamURL = content["WebcamUrl"] {
            self.webCamURL = webCamURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if let lastMeasurement = content["LastMeasurementTime"] {
            self.lastMeasurement = DataManager.shared.dateFromString(lastMeasurement)
        }
    }


    func updateWithWatchContent(_ content: [String:AnyObject] ) {
        if let hidden = content["hidden"] as? Int {
            self.isHidden = hidden as NSNumber?
        }

        if let order = content["order"] as? Int {
            self.order = order as NSNumber?
        }

        if let stationId = content["stationId"] as? Int {
            self.stationId = stationId as NSNumber?
        }

        if let stationName = content["stationName"] as? String {
            self.stationName = stationName
        }

        if let lat = content["latitude"] as? Double {
            self.coordinateLat = lat as NSNumber?
        }

        if let lon = content["longitude"] as? Double {
            self.coordinateLon = lon as NSNumber?
        }
    }
}
