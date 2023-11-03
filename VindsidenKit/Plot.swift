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

@Model 
public final class Plot {
    public var dataId: Int = 0
    public var plotTime: Date = Date()
    public var tempAir: Double = -999
    public var tempWater: Double = -999
    public var windAvg: Double = 0
    public var windDir: Double = 0
    public var windMax: Double = 0
    public var windMin: Double = 0

    @Relationship(inverse: \Station.plots)
    public var station: Station?

    internal init(dataId: Int, plotTime: Date, tempAir: Double, tempWater: Double, windAvg: Double, windDir: Double, windMax: Double, windMin: Double) {
        self.dataId = dataId
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

extension Plot: Plottable {
    public typealias PrimitivePlottable = Date

    public var primitivePlottable: Date {
        return plotTime
    }

    public convenience init?(primitivePlottable: Date) {
        nil
    }
}

extension Plot {
    @MainActor
    public static func existing(for dataId: Int, with stationId: Int, in modelContext: ModelContext) -> Plot? {
        var fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\Plot.dataId, order: .forward)])
        fetchDescriptor.predicate = #Predicate { $0.dataId == dataId && $0.station?.stationId == stationId }
        fetchDescriptor.fetchLimit = 1

        guard let plots = try? modelContext.fetch(fetchDescriptor) else {
            return nil
        }

        return plots.first
    }

    @MainActor
    public class func updatePlots(_ plots: [[String: String]], in modelContext: ModelContext) async throws -> Int {
        guard
            let stationPlot = plots.first,
            let stationString = stationPlot["StationID"],
            let stationId = Int(stationString),
            let station = Station.existing(for: stationId, in: modelContext)
        else {
            return 0
        }

        for plotContent in plots {
            guard
                let unwrapped = plotContent["DataID"],
                let dataId = Int(unwrapped),
                Plot.existing(for: dataId, with: stationId, in: modelContext) == nil
            else {
                continue
            }

            let plot = Plot()

            plot.updateWithContent(plotContent)
            plot.station = station

            modelContext.insert(plot)
        }

        let numInserted = modelContext.insertedModelsArray.count

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Save plot failed: \(error.localizedDescription)")
        }

        return numInserted
    }

    func updateWithContent( _ content: [String: String] ) {
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