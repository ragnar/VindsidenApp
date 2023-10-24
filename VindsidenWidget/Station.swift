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

import WeatherBoxView
import Units

@Model
public final class Station {
    public var city: String?
    public var coordinateLat: Double? = 0
    public var coordinateLon: Double? = 0
    public var copyright: String?
    public var isHidden: Bool = true
    public var lastMeasurement: Date?
    public var lastRefreshed: Date?
    public var order: Int16 = 0
    @Attribute(.unique)
    public var stationId: Int32? = 0
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
        let temp: TempUnit = UserSettings.shared.selectedTempUnit
        let wind: WindUnit = UserSettings.shared.selectedWindUnit
        let direction = DirectionUnit(rawValue: Double(plot.windDir)) ?? .unknown
        let units = WidgetData.Units(wind: wind, rain: .mm, temp: temp, baro: .hPa, windDirection: direction)
        let data = WidgetData(name: name,
                              windAngle: Double(plot.windDir),
                              windSpeed: Double(plot.windMin).toUnit(wind),
                              windAverage: Double(plot.windAvg).toUnit(wind),
                              windAverageMS: Double(plot.windAvg),
                              windGust: Double(plot.windMax).toUnit(wind),
                              units: units,
                              lastUpdated: plot.plotTime
        )

        return data
    }
}
