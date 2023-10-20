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

@Model
final class _Station {
    @Attribute(.unique)
    var stationId: Int

    var city: String?
    var coordinateLat: Double?
    var coordinateLon: Double?
    var copyright: String?
    var isHidden: Bool
    var lastMeasurement: Date
    var lastRefreshed: Date?
    var order: Int
    var stationName: String?
    var stationText: String?
    var statusMessage: String?
    var webCamImage: String?
    var webCamText: String?
    var webCamURL: String?
    var yrURL: String?

    @Relationship(deleteRule: .cascade, inverse: \Plot.station)
    var plots: [Plot]

    internal init(city: String, coordinateLat: Double, coordinateLon: Double, copyright: String, isHidden: Bool, lastMeasurement: Date, lastRefreshed: Date, order: Int, stationId: Int, stationName: String, stationText: String, statusMessage: String, webCamImage: String, webCamText: String, webCamURL: String, yrURL: String) {
        self.city = city
        self.coordinateLat = coordinateLat
        self.coordinateLon = coordinateLon
        self.copyright = copyright
        self.isHidden = isHidden
        self.lastMeasurement = lastMeasurement
        self.lastRefreshed = lastRefreshed
        self.order = order
        self.stationId = stationId
        self.stationName = stationName
        self.stationText = stationText
        self.statusMessage = statusMessage
        self.webCamImage = webCamImage
        self.webCamText = webCamText
        self.webCamURL = webCamURL
        self.yrURL = yrURL
        self.plots = []
    }
}


@Model
final class Station {
    var city: String?
    var coordinateLat: Double? = 0
    var coordinateLon: Double? = 0
    var copyright: String?
    var isHidden: Bool = true
    var lastMeasurement: Date?
    var lastRefreshed: Date?
    var order: Int16 = 0
    @Attribute(.unique) var stationId: Int32? = 0
    var stationName: String?
    var stationText: String?
    var statusMessage: String?
    var webCamImage: String?
    var webCamText: String?
    var webCamURL: String?
    var yrURL: String?
    @Relationship(deleteRule: .cascade) var plots: [Plot]?

    public init() { }
}
