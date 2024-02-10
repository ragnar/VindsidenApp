//
//  PreviewSampleData.swift
//  VindsidenWidgetExtension
//
//  Created by Ragnar Henriksen on 16/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftData
import SwiftUI

public actor PreviewSampleData {
    @MainActor
    public static var container: ModelContainer = {
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
        let station = Station()
        station.city = "Oslo"
        station.stationId = 1
        station.stationName = "Larkollen"

        return station
    }
}

extension Plot {
    static var preview: [Plot] {
        var plots = [Plot]()

        plots.append(Plot(dataId: 0, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*135)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 1, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*120)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 2, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*105)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 3, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*90)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 4, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*75)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 5, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*60)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 6, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*45)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 7, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*30)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 8, stationId: 1, plotTime: Date().addingTimeInterval(-1*(3600*15)), tempAir: 0, tempWater: 0, windAvg: .random(in: 7...9), windDir: .random(in: 170...190), windMax: .random(in: 9...11), windMin: .random(in: 6...7)))
        plots.append(Plot(dataId: 9, stationId: 1, plotTime: Date(), tempAir: 0, tempWater: 0, windAvg: 5, windDir: 180, windMax: 6, windMin: 4))
        //plots.forEach { $0.station = Station.preview }

        return plots
    }
}
