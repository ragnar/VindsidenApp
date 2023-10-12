//
//  Plot.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@Model
final class Plot {
    @Attribute(.unique)
    var dataId: Int
    var plotTime: Date
    var tempAir: Double
    var tempWater: Double
    var windAvg: Double
    var windDir: Double
    var windMax: Double
    var windMin: Double
    var station: Station?

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
}
