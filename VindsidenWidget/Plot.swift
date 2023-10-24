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

@Model 
public final class Plot {
    public var dataId: Int64 = 0
    public var plotTime: Date = Date()
    public var tempAir: Float = -999
    public var tempWater: Float = -999
    public var windAvg: Float = 0
    public var windDir: Float = 0
    public var windMax: Float = 0
    public var windMin: Float = 0
    public var station: Station?

    internal init(dataId: Int64, plotTime: Date, tempAir: Float, tempWater: Float, windAvg: Float, windDir: Float, windMax: Float, windMin: Float) {
        self.dataId = dataId
        self.plotTime = plotTime
        self.tempAir = tempAir
        self.tempWater = tempWater
        self.windAvg = windAvg
        self.windDir = windDir
        self.windMax = windMax
        self.windMin = windMin
    }
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
