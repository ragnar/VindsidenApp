//
//  Plot.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import Charts
import Observation
import OSLog

public struct SendablePlot: Sendable {
    public let dataId: Int
    public let stationId: Int
    public let plotTime: Date
    public let tempAir: Double
    public let tempWater: Double
    public let windAvg: Double
    public let windDir: Double
    public let windMax: Double
    public let windMin: Double

    public init(dataId: Int, stationId: Int, plotTime: Date, tempAir: Double, tempWater: Double, windAvg: Double, windDir: Double, windMax: Double, windMin: Double) {
        self.dataId = dataId
        self.stationId = stationId
        self.plotTime = plotTime
        self.tempAir = tempAir
        self.tempWater = tempWater
        self.windAvg = windAvg
        self.windDir = windDir
        self.windMax = windMax
        self.windMin = windMin
    }

    public init(from plot: Plot) {
        self.dataId = plot.dataId
        self.stationId = plot.stationId
        self.plotTime = plot.plotTime
        self.tempAir = plot.tempAir
        self.tempWater = plot.tempWater
        self.windAvg = plot.windAvg
        self.windDir = plot.windDir
        self.windMax = plot.windMax
        self.windMin = plot.windMin
    }
}

extension SendablePlot: Plottable {
    public typealias PrimitivePlottable = Date

    public var primitivePlottable: Date {
        return plotTime
    }

    public init?(primitivePlottable: Date) {
        nil
    }
}

extension Array where Element == SendablePlot {
    public subscript(id: Date?) -> SendablePlot? {
        return first { $0.plotTime == id }
    }
}

@Model
public final class Plot {
    public var dataId: Int = 0
    public var stationId: Int = 0
    public var plotTime: Date = Date(timeIntervalSince1970: 0)
    public var tempAir: Double = -999
    public var tempWater: Double = -999
    public var windAvg: Double = 0
    public var windDir: Double = 0
    public var windMax: Double = 0
    public var windMin: Double = 0

    internal init(dataId: Int, stationId: Int, plotTime: Date, tempAir: Double, tempWater: Double, windAvg: Double, windDir: Double, windMax: Double, windMin: Double) {
        self.dataId = dataId
        self.stationId = stationId
        self.plotTime = plotTime
        self.tempAir = tempAir
        self.tempWater = tempWater
        self.windAvg = windAvg
        self.windDir = windDir
        self.windMax = windMax
        self.windMin = windMin
    }

    public init() { }
}

//extension Array where Element: Plot {
//    public subscript(id: Date?) -> Plot? {
//        return first { $0.plotTime == id }
//    }
//}

//extension Plot: Plottable {
//    public typealias PrimitivePlottable = Date
//
//    public var primitivePlottable: Date {
//        return plotTime
//    }
//
//    public convenience init?(primitivePlottable: Date) {
//        nil
//    }
//}

extension Plot {
    static func existing(for dataId: Int, with stationId: Int, in modelContext: ModelContext) -> Plot? {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.dataId, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.dataId == dataId && $0.stationId == stationId }
        fetchDescriptor.fetchLimit = 1

        guard let plots = try? modelContext.fetch(fetchDescriptor) else {
            return nil
        }

        return plots.first
    }

    func updateWithContent( _ content: [String: String] ) {
        if let stationString = content["StationID"], let stationId = Int(stationString) {
            self.stationId = stationId
        }

        if let unwrapped = content["Time"] {
            self.plotTime = DataManager.shared.dateFromString(unwrapped)
        }

        if let unwrapped = content["WindAvg"], let avg = Double(unwrapped) {
            self.windAvg = avg
        }

        if let unwrapped = content["WindMax"], let max = Double(unwrapped) {
            self.windMax = max
        }

        if let unwrapped = content["WindMin"], let min = Double(unwrapped) {
            self.windMin = min
        }

        if let unwrapped = content["DirectionAvg"], let dir = Double(unwrapped) {
            self.windDir = dir
        }

        if let unwrapped = content["Temperature1"], let temp = Double(unwrapped) {
            self.tempAir = temp
        }

        if let unwrapped = content["DataID"], let dataId = Int(unwrapped) {
            self.dataId = dataId
        }
    }
}
