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
final class Plot {
//    @Attribute(.unique)
    var dataId: Int64 = 0
    var plotTime: Date = Date()
    var tempAir: Float = -999
    var tempWater: Float = -999
    var windAvg: Float = 0
    var windDir: Float = 0
    var windMax: Float = 0
    var windMin: Float = 0
    var station: Station?

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
    typealias PrimitivePlottable = Date

    var primitivePlottable: Date {
        return plotTime
    }

    convenience init?(primitivePlottable: Date) {
        nil
    }
}
