//
//  Station.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import Observation
import AppIntents
import MapKit
import OSLog

import WeatherBoxView
import Units

@Model
public final class Station {
    public var city: String?
    public var coordinateLat: Double? = 0
    public var coordinateLon: Double? = 0
    public var copyright: String?
    public var isHidden: Bool = true {
        didSet {
            if isHidden {
                DataManager.shared.removeStationFromIndex(self)
            } else {
                DataManager.shared.addStationToIndex(self)
            }
        }
    }
    public var lastMeasurement: Date?
    public var lastRefreshed: Date?
    public var order: Int16 = 0
    @Attribute(.unique)
    public var stationId: Int = 0
    public var stationName: String?
    public var stationText: String?
    public var statusMessage: String?
    public var webCamImage: String?
    public var webCamText: String?
    public var webCamURL: String?
    public var yrURL: String?
    @Relationship(deleteRule: .cascade) 
    public var plots: [Plot]?

    public init() { }
}

extension Station {
    @MainActor
    public func lastPlot() -> Plot? {
        return plots?.sorted(by: { $0.dataId > $1.dataId } ).first
    }

    @MainActor
    public func widgetData() -> WidgetData {
        guard
            let plots,
            let plot = plots.sorted(by: { $0.dataId > $1.dataId } ).first
        else {
            return WidgetData()
        }

        let name = stationName ?? "Unknown"
        let stationId: String? = "\(stationId)"
        let temp: TempUnit = UserSettings.shared.selectedTempUnit
        let wind: WindUnit = UserSettings.shared.selectedWindUnit
        let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
        let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)
        let data = WidgetData(customIdentifier: stationId,
                              name: name,
                              windAngle: Double(plot.windDir),
                              windSpeed: Double(plot.windMin).fromUnit(.metersPerSecond).toUnit(wind),
                              windAverage: Double(plot.windAvg).fromUnit(.metersPerSecond).toUnit(wind),
                              windAverageMS: Double(plot.windAvg),
                              windGust: Double(plot.windMax).fromUnit(.metersPerSecond).toUnit(wind),
                              temp: Double(plot.tempAir).toUnit(temp),
                              units: units,
                              lastUpdated: plot.plotTime
        )

        return data
    }
}

extension Station {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: (self.coordinateLat)!, longitude: (self.coordinateLon)!)
    }
}

extension Station {
    @MainActor
    public static func visible(in modelContext: ModelContext) -> [Station] {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.isHidden == false }

        guard let stations = try? modelContext.fetch(fetchDescriptor) else {
            return []
        }

        return stations
    }

    @MainActor
    public static func existing(for stationId: Int, in modelContext: ModelContext) -> Station? {
        let station32 = Int(stationId)
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.stationId == station32 }
        fetchDescriptor.fetchLimit = 1

        guard let stations = try? modelContext.fetch(fetchDescriptor) else {
            return nil
        }

        return stations.first
    }

    @MainActor
    public static func hide(stationName: String, in modelContext: ModelContext) {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.stationName == stationName }

        guard let stations = try? modelContext.fetch(fetchDescriptor) else {
            return
        }

        stations.forEach { $0.isHidden = true }

        try? modelContext.save()
    }

    @MainActor
    public static func webcamurl(stationName: String, in modelContext: ModelContext) -> URL? {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.stationName == stationName }
        fetchDescriptor.fetchLimit = 1

        guard
            let stations = try? modelContext.fetch(fetchDescriptor),
            let station = stations.first,
            let webCamURL = station.webCamImage,
            let url = URL(string: webCamURL)
        else {
            return nil
        }

        return url
    }
}

extension Station {
    @MainActor
    public class func updateWithFetchedContent(_ content: [[String: String]], in modelContext: ModelContext) -> Bool {
        let stationIds = content.map { return Int($0["StationID"]!)! }

        Station.removeStaleStations(stationIds, in: modelContext)

        var inserted = false
        var order = Station.maxOrder(in: modelContext) ?? 200

        for stationContent in content {
            guard 
                let stationIdString = stationContent["StationID"],
                let stationId = Int(stationIdString)
            else {
                Logger.persistence.debug("No stationId")
                continue
            }

            let station: Station

            if let existing = Station.existing(for: stationId, in: modelContext) {
                station = existing
            } else {
                inserted = true
                station = Station()

                if stationId == 60 {
                    station.order = 101
                    station.isHidden = false
                } else {
                    order += 1
                    station.order = order
                }

                modelContext.insert(station)
            }

            station.updateWithContent(stationContent, stationId: stationId)
        }

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save failed: \(error.localizedDescription)")
        }

        return inserted
    }

    @MainActor
    public class func updateWithWatchContent(_ content: [[String: AnyObject]], in modelContext: ModelContext) async {
        let stationIds = content.map { return $0["stationId"] as! Int }

        Station.removeStaleStations(stationIds, in: modelContext)

        for stationContent in content {
            guard let stationId = stationContent["stationId"] as? Int else {
                Logger.persistence.debug("No stationId")
                continue
            }

            let station: Station

            if let existing = Station.existing(for: stationId, in: modelContext) {
                station = existing
            } else {
                station = Station()
                modelContext.insert(station)
            }

            station.updateWithWatchContent(stationContent)
        }

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    public class func removeStaleStations(_ stations: [Int], in modelContext: ModelContext) {
        do {
            let predicate = #Predicate<Station> { station in
                stations.contains(station.stationId) == false
            }

            try modelContext.delete(model: Station.self, where: predicate)

            Logger.persistence.debug("Deleted \(modelContext.deletedModelsArray.count) stations")

            try modelContext.save()
        } catch {
            Logger.persistence.error("Deleting failed: \(error.localizedDescription)")
        }
    }

    func updateWithContent(_ content: [String: String], stationId: Int) {
        self.stationId = stationId

        if let name = content["Name"] {
            self.stationName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let text = content["Text"] {
            self.stationText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let city = content["City"] {
            self.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let copyright = content["Copyright"] {
            self.copyright = copyright.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let statusMessage = content["StatusMessage"] {
            self.statusMessage = statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let coordinate = content["Latitude"], let lat = Double(coordinate) {
            self.coordinateLat = lat
        }

        if let coordinate = content["Longitude"], let lng = Double(coordinate) {
            self.coordinateLon = lng
        }

        if let yrURL = content["MeteogramUrl"] {
            self.yrURL = yrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let webCamImage = content["WebcamImage"] {
            self.webCamImage = webCamImage.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let webCamText = content["WebcamText"] {
            self.webCamText = webCamText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let webCamURL = content["WebcamUrl"] {
            self.webCamURL = webCamURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let lastMeasurement = content["LastMeasurementTime"] {
            self.lastMeasurement = DataManager.shared.dateFromString(lastMeasurement)
        }
    }

    func updateWithWatchContent(_ content: [String:AnyObject] ) {
        if let hidden = content["hidden"] as? Bool {
            self.isHidden = hidden
        }

        if let order = content["order"] as? Int16 {
            self.order = order
        }

        if let stationId = content["stationId"] as? Int {
            self.stationId = stationId
        }

        if let stationName = content["stationName"] as? String {
            self.stationName = stationName
        }

        if let lat = content["latitude"] as? Double {
            self.coordinateLat = lat
        }

        if let lon = content["longitude"] as? Double {
            self.coordinateLon = lon
        }
    }
}

extension Station {
    public class func maxOrder(in modelContext: ModelContext) -> Int16? {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Station.order, order: .reverse)])
        fetchDescriptor.fetchLimit = 1

        let result = try? modelContext.fetch(fetchDescriptor)
     
        return result?.first?.order
    }
}
