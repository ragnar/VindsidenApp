//
//  StationView.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 16/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import OSLog
import VindsidenKit
import Units

public class PlotObservable: ObservableObject {
    @Published public var plot: CDPlot? {
        didSet {
            Logger.debugging.debug("Plot was set. \(String(describing: self.plot?.plotTime))")
        }
    }

    @Published public var plots: [CDPlot] = [] {
        didSet {
            Logger.debugging.debug("Plots was set. \(self.plots.count)")
        }
    }

    @Published public var station: CDStation? {
        didSet {
            Logger.debugging.debug("Station was set. \(String(describing: self.station?.stationName))")
        }
    }

    func tempString(value: NSNumber?, for unit: TempUnit) -> String {
        guard 
            let value = value?.doubleValue,
            value != -999
        else {
            return "-.- \(unit.symbol)"
        }

        let converted = value.toUnit(unit)

        return unit.formatted(value: converted)
    }

    func windString(value: NSNumber?, for unit: WindUnit) -> String {
        guard let value = value?.doubleValue else {
            return "-.- \(unit.symbol)"
        }

        let converted = value.fromUnit(.metersPerSecond).toUnit(unit)

        return unit.formatted(value: converted)
    }

    func windStringInBeaufort(value: NSNumber?) -> String {
        guard let value = value?.doubleValue else {
            return "-"
        }

        let converted = value.fromUnit(.metersPerSecond).toUnit(.beaufort)

        return converted.formatted(.number.precision(.fractionLength(0)))
    }

    func windDirectionString(value: NSNumber?, text: String?) -> String {
        guard
            let value = value?.intValue,
            let text
        else {
            return "-"
        }

        return "\(value)° (\(text))"
    }
}

struct StationView: View {
    @EnvironmentObject private var settings: UserObservable
    @ObservedObject var observer: PlotObservable

    var updater: () -> ()

    var body: some View {
        if let stationName = observer.station?.stationName {
            GeometryReader(content: { geometry in
                VStack(alignment: .leading) {
                    Text(stationName)
                        .font(.system(size: 62, weight: .ultraLight))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    if let plot = observer.plot, let plotTime = plot.plotTime {
                        Text(plotTime, style: .relative)
                            .padding(.bottom, 16)
                        LazyVGrid(columns: [
                            GridItem(.fixed((geometry.size.width - 16) / 2)),
                            GridItem(.fixed((geometry.size.width - 16) / 2)),
                        ], alignment: .leading, spacing: 8, content: {
                            InfoView(label: "Wind Speed", value: observer.windString(value: plot.windMin, for: settings.windUnit))
                            InfoView(label: "Average", value: observer.windString(value: plot.windAvg, for: settings.windUnit))
                            InfoView(label: "Wind Gust", value: observer.windString(value: plot.windMax, for: settings.windUnit))
                            InfoView(label: "Wind Beaufort", value: observer.windStringInBeaufort(value: plot.windMin))
                            InfoView(label: "Wind Direction", value: observer.windDirectionString(value: plot.windDir, text: plot.windDirectionString()))
                            InfoView(label: "Temp Air", value: observer.tempString(value: plot.tempAir, for: settings.tempUnit))
                        })
                    } else {
                        Text("Updating")
                    }
                    Spacer()
                    SwiftUIPlotGraph(observer: observer)
                        .frame(minHeight: 200, maxHeight: 240)
                        .padding(.bottom)
                        .environmentObject((UIApplication.shared.delegate as? RHCAppDelegate)!.settings)
                        .environment(\.managedObjectContext, DataManager.shared.viewContext())
                }
            })
            .onChange(of: settings.lastChanged) { _, _ in
                Logger.debugging.debug("Last changed for: \(stationName)")
                updater()
            }
        } else {
            EmptyView()
                .onChange(of: settings.lastChanged) { _, _ in
                    Logger.debugging.debug("Last changed for: unknown station name")
                    updater()
                }
        }
    }
}


struct InfoView: View {
    var label: LocalizedStringKey
    var value: String

    var body: some View {
        VStack(alignment: .center) {
            Text(label)
                .font(.footnote)
            Text(value)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding([.top, .bottom], 6)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
