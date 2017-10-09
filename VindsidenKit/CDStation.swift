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

@objc(CDStation)
open class CDStation: NSManagedObject, MKAnnotation {

    @NSManaged func addPlotsObject( _ value: CDPlot)
    @NSManaged func removePlotsObject( _ value: CDPlot)
    @NSManaged func addPlots( _ value: NSSet)
    @NSManaged func removePlots( _ value: NSSet)

    // MARK: - MKAnnotation


    open var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: (self.coordinateLat?.doubleValue)!, longitude: (self.coordinateLon?.doubleValue)!)
    }


    open var title: String? {
        return self.stationName
    }


    open var subtitle: String? {
        return self.city
    }


    @objc open class func existingStationWithId( _ stationId:Int, inManagedObjectContext managedObjectContext: NSManagedObjectContext) throws -> CDStation {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStation")
        request.predicate = NSPredicate(format: "stationId == \(stationId)")
        request.fetchLimit = 1

        let result = try managedObjectContext.fetch(request) as! [CDStation]

        if result.count > 0 {
            return result.first!
        }

        throw NSError(domain: AppConfig.Bundle.appName, code: -1, userInfo: nil)
    }


    open class func newOrExistingStationWithId( _ stationId: Int, inManagedObectContext managedObjectContext: NSManagedObjectContext) -> CDStation {
        do {
            let existing = try CDStation.existingStationWithId(stationId, inManagedObjectContext: managedObjectContext)
            return existing
        } catch {
            let entity = NSEntityDescription.entity(forEntityName: "CDStation", in: managedObjectContext)!
            let station = CDStation(entity: entity, insertInto: managedObjectContext)
            return station
        }
    }


    open class func searchForStationName( _ stationName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> CDStation? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStation")
        request.predicate = NSPredicate(format: "stationName contains[cd] %@", argumentArray: [stationName])
        request.fetchLimit = 1

        do {
            let result = try managedObjectContext.fetch(request) as! [CDStation]
            if result.count > 0 {
                return result.first!
            }
        } catch {
            return nil
        }

        return nil
    }


    open class func maxOrderForStationsInManagedObjectContext( _ managedObjectContext: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStation")
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


    @objc open class func numberOfVisibleStationsInManagedObjectContext( _ managedObjectContext: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStation")
        request.predicate = NSPredicate(format: "isHidden == NO")

        do {
            let count = try managedObjectContext.count(for: request)
            return count
        } catch {
            return 0
        }
    }


    @objc open class func visibleStationsInManagedObjectContext( _ managedObjectContext: NSManagedObjectContext, limit: Int = 0) -> [CDStation] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDStation")
        request.fetchBatchSize = 20
        request.predicate = NSPredicate(format: "isHidden == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        if limit > 0 {
            request.fetchLimit = limit
        }

        do {
            let result = try managedObjectContext.fetch(request) as! [CDStation]
            return result
        } catch {
            return []
        }
    }

    @objc open func lastRegisteredPlot() -> CDPlot? {
        let inDate = Date().addingTimeInterval(-1*(AppConfig.Global.plotHistory-1)*3600)

        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let inputComponents = (gregorian as NSCalendar).components([.year, .month, .day, .hour], from: inDate)

        guard let outDate = gregorian.date(from: inputComponents) else {
            DLOG("Outdate missing")
            return nil
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPlot")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "station == %@ AND plotTime >= %@", argumentArray: [self, outDate] )
        request.sortDescriptors = [NSSortDescriptor(key: "plotTime", ascending: false)]

        do {
            let result = try self.managedObjectContext!.fetch(request)
            if let first = result.first as? CDPlot {
                return first
            }
        } catch {
            return nil
        }

        return nil
    }


    @objc open class func updateWithFetchedContent( _ content: [[String:String]], inManagedObjectContext managedObjectContext: NSManagedObjectContext, completionHandler: ((Bool) -> Void)? = nil) {

        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = managedObjectContext
        childContext.undoManager = nil
        childContext.mergePolicy = NSOverwriteMergePolicy

        childContext.perform { () -> Void in

            var order = CDStation.maxOrderForStationsInManagedObjectContext(childContext)
            var newStations = false

            if order == 0 {
                order = 200
            }

            let stationIds = content.map { return Int($0["StationID"]!)! }
            Datamanager.sharedManager.removeStaleStationsIds(stationIds, inManagedObjectContext: childContext)

            for stationContent in content {
                guard let stationIdString = stationContent["StationID"] else {
                    DLOG("No stationId")
                    continue
                }

                let stationId = Int(stationIdString)!
                let station = CDStation.newOrExistingStationWithId(stationId, inManagedObectContext: childContext)
                station.updateWithContent(stationContent)

                #if Debug
                    if station.stationId == 1 {
                        station.webCamImage = "http://www.tasken.no/webcam/capture1000M.jpg"
                    }
                #endif

                if station.isInserted {
                    newStations = true
                    if station.stationId == 1 {
                        station.order = 101
                        station.isHidden = false
                        #if os(iOS)
                            Datamanager.sharedManager.addStationToIndex(station)
                        #endif
                    } else {
                        order += 1
                        station.order = order as NSNumber?
                        station.isHidden = true
                    }
                }
            }

            /*
            guard let entity = NSEntityDescription.entityForName("CDStation", inManagedObjectContext: childContext) else {
                DLOG("Missing entity")
                completionHandler?(false)
                return;
            }

            var gotNewStations = false

            for stationContent in content {
                guard let _ = stationContent["StationID"] as String? else {
                    DLOG("No stationId")
                    continue
                }

                let station = CDStation(entity: entity, insertIntoManagedObjectContext: childContext)
                station.updateWithContent(stationContent)

                if station.inserted {
                    gotNewStations = true

                    if station.order != 0 {
                        if station.stationId == 1 {
                            station.isHidden = false
                        }
                    }
                }
            }
            */

            do {
                try childContext.save()

                managedObjectContext.perform {
                    do {
                        try managedObjectContext.save()
                    } catch let error as NSError {
                        DLOG("Save failed: \(error)")
                        DLOG("Save failed: \(error.localizedDescription)")
                    } catch {
                        DLOG("Save failed: \(error)")
                    }
                    completionHandler?(newStations)
                    return
                }
            } catch let error as NSError {
                DLOG("Error: \(error.userInfo.keys)")
            } catch {
                DLOG("Error: \(error)")

            }
            completionHandler?(newStations)
            return
        }
    }



    open class func updateWithWatchContent( _ content: [[String:AnyObject]], inManagedObjectContext managedObjectContext: NSManagedObjectContext, completionHandler: ((Bool) -> Void)? = nil) {
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = managedObjectContext
        childContext.undoManager = nil
        childContext.mergePolicy = NSOverwriteMergePolicy

        childContext.perform { () -> Void in
            for stationContent in content {
                guard let stationId = stationContent["stationId"] as? Int else {
                    DLOG("No stationId")
                    continue
                }

                let station = CDStation.newOrExistingStationWithId(stationId, inManagedObectContext: childContext)
                station.updateWithWatchContent(stationContent)
            }

            let stationIds: [Int] = content.map { return $0["stationId"] as! Int }
            Datamanager.sharedManager.removeStaleStationsIds(stationIds, inManagedObjectContext: childContext)

            do {
                try childContext.save()

                managedObjectContext.perform {
                    do {
                        try managedObjectContext.save()
                    } catch let error as NSError {
                        DLOG("Save failed: \(error)")
                        DLOG("Save failed: \(error.localizedDescription)")
                    } catch {
                        DLOG("Save failed: \(error)")
                    }
                    completionHandler?(false)
                    return
                }
            } catch let error as NSError {
                DLOG("Error: \(error.userInfo.keys)")
            } catch {
                DLOG("Error: \(error)")
                
            }
            completionHandler?(false)
            return
        }
    }


    func updateWithContent( _ content: [String:String] ) {
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
            self.lastMeasurement = Datamanager.sharedManager.dateFromString(lastMeasurement)
        }
    }


    func updateWithWatchContent( _ content: [String:AnyObject] ) {
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

