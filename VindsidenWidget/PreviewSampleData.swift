//
//  PreviewSampleData.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 16/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftData
import SwiftUI

actor PreviewSampleData {
    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([Station.self, Plot.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let sampleData: [any PersistentModel] = Plot.preview

        sampleData.forEach {
            container.mainContext.insert($0)
        }
        return container
    }()
}


extension Station {
    static var preview: Station {
        return Station(city: "Oslo",
                       coordinateLat: 0,
                       coordinateLon: 0,
                       copyright: "",
                       isHidden: false,
                       lastMeasurement: Date(),
                       lastRefreshed: Date(),
                       order: 0,
                       stationId: 1,
                       stationName: "Larkollen",
                       stationText: "",
                       statusMessage: "",
                       webCamImage: "",
                       webCamText: "",
                       webCamURL: "",
                       yrURL: ""
        )
    }
}

extension Plot {
    static var preview: [Plot] {
        var plots = [Plot]()

        plots.append(Plot(dataId: 0, plotTime: Date().addingTimeInterval(-1*(3600*135)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 1, plotTime: Date().addingTimeInterval(-1*(3600*120)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 2, plotTime: Date().addingTimeInterval(-1*(3600*105)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 3, plotTime: Date().addingTimeInterval(-1*(3600*90)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 4, plotTime: Date().addingTimeInterval(-1*(3600*75)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 5, plotTime: Date().addingTimeInterval(-1*(3600*60)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 6, plotTime: Date().addingTimeInterval(-1*(3600*45)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 7, plotTime: Date().addingTimeInterval(-1*(3600*30)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 8, plotTime: Date().addingTimeInterval(-1*(3600*15)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 9, plotTime: Date(), tempAir: 0, tempWater: 0, windAvg: 5, windDir: 180, windMax: 6, windMin: 4))
        plots.forEach { $0.station = Station.preview }

        return plots
    }
}
