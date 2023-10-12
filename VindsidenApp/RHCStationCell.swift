//
//  RHCStationCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import UIKit
import VindsidenKit
import SwiftUI
import Charts
import SwiftData

@objc
class RHCStationCell: UICollectionViewCell {
    @IBOutlet weak var stationNameLabel: UILabel?
    @IBOutlet weak var updatedAtLabel: UILabel?
    @IBOutlet weak var cameraButton: UIButton?
    @IBOutlet weak var graphView: UIView?
    @IBOutlet weak var stationView: RHCStationInfo?

    var plotGraph: SwiftUIPlotGraph?
    var plotGraphView: UIView?

    @objc
    weak var currentStation: CDStation? {
        didSet {
            guard let station = currentStation else {
                return
            }

            stationNameLabel?.text = station.stationName
//            graphView?.copyright = station.copyright

            if plotGraph == nil {
                addPlotGraph()
            }

            displayPlots()

            updatedTimer?.invalidate()
            let updatedTimer = Timer(fireAt: Date(),
                                     interval: 1,
                                     target: self,
                                     selector: #selector(updateLastUpdatedLabel),
                                     userInfo: nil,
                                     repeats: true)

            RunLoop.current.add(updatedTimer, forMode: .default)
            self.updatedTimer = updatedTimer
        }
    }

    var updatedTimer: Timer?

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        return formatter
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        updatedAtLabel?.text = ""
        cameraButton?.alpha = 0.0
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        updatedTimer?.invalidate()
        updatedTimer = nil

        updatedAtLabel?.text = NSLocalizedString("LABEL_UPDATING", comment: "Updating")

        cameraButton?.alpha = 0.0
        stationView?.resetInfoLabels()
        plotGraphView?.removeFromSuperview()
        plotGraph = nil
    }

    func addPlotGraph() {
        guard
            let graphView,
            let stationId = currentStation?.stationId else {
            return
        }

        let plotGraph = SwiftUIPlotGraph(stationId: stationId.intValue)
        let vc = UIHostingController(rootView: plotGraph
            .environment(\.managedObjectContext,
                          DataManager.shared.viewContext())
        )

        let swiftuiView = vc.view!
        swiftuiView.translatesAutoresizingMaskIntoConstraints = false

        graphView.addSubview(swiftuiView)
        self.plotGraphView = swiftuiView
        self.plotGraph = plotGraph

        NSLayoutConstraint.activate([
            swiftuiView.leadingAnchor.constraint(equalTo: graphView.leadingAnchor),
            swiftuiView.trailingAnchor.constraint(equalTo: graphView.trailingAnchor),
            swiftuiView.bottomAnchor.constraint(equalTo: graphView.bottomAnchor),
            swiftuiView.topAnchor.constraint(equalTo: graphView.topAnchor),
        ])
    }

    @objc
    func displayPlots() {
        DispatchQueue.main.async { [weak self] in
            self?.syncDisplayPlots()
        }
    }

    func syncDisplayPlots() {
        guard
            let gregorian = NSCalendar(identifier: .gregorian),
            let currentStation,
            let context = currentStation.managedObjectContext
        else {
            return
        }

//        let inDate = Date().addingTimeInterval(-1*(kPlotHistoryHours-1)*3600)
        let inDate = Date().addingTimeInterval(-1*(5-1)*3600)
        let inputComponents = gregorian.components([.year, .month, .day, .hour], from: inDate)
        let outDate = gregorian.date(from: inputComponents) ?? Date()

        let fetchRequest = CDPlot.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "station == %@ AND plotTime >= %@", currentStation, outDate as CVarArg)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "plotTime", ascending: false),
        ]

        let cdplots: [CDPlot] = (try? context.fetch(fetchRequest)) ?? []

        if cdplots.isEmpty {
            updatedAtLabel?.text = NSLocalizedString("LABEL_NOT_UPDATED", comment: "Not updated")
        } else {
            stationView?.update(with: cdplots.first)
            updateLastUpdatedLabel()
        }
    }

    @objc
    func updateLastUpdatedLabel() {
        guard let plot = currentStation?.lastRegisteredPlot() else {
            updatedAtLabel?.text = NSLocalizedString("LABEL_NOT_UPDATED", comment: "Not updated")
            return
        }

        if plot.plotTime?.compare(Date()) == .orderedAscending {
            updatedAtLabel?.text = AppConfig.sharedConfiguration.relativeDate(plot.plotTime)
        } else {
            updatedAtLabel?.text = AppConfig.sharedConfiguration.relativeDate(nil)
        }
    }
}

struct SwiftUIPlotGraph: View {
    @Environment(\.managedObjectContext) private var viewContext

    var stationId: Int

    @FetchRequest private var plots: FetchedResults<CDPlot>

    init(stationId: Int) {
        let gregorian = NSCalendar(identifier: .gregorian)!
        let inDate = Date().addingTimeInterval(-1*(5-1)*3600)
        let inputComponents = gregorian.components([.year, .month, .day, .hour], from: inDate)
        let outDate = gregorian.date(from: inputComponents) ?? Date()

        self.stationId = stationId
        self._plots = FetchRequest<CDPlot>(sortDescriptors: [SortDescriptor(\.plotTime)],
                                           predicate: NSPredicate(format: "station.stationId == %d AND plotTime >= %@", stationId, outDate as CVarArg)
        )
    }

    var body: some View {
        Chart {
            ForEach(plots) { value in
                AreaMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    yStart: .value("Lull", value.windMin!.doubleValue),
                    yEnd: .value("Gust", value.windMax!.doubleValue)
                )
                .foregroundStyle(by: .value("Series", "Variation"))

                LineMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    y: .value("Speed Min", value.windMin!.doubleValue)
                )
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: []))
                .foregroundStyle(by: .value("Series", "Variation Min"))

                LineMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    y: .value("Speed Max", value.windMax!.doubleValue)
                )
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: []))
                .foregroundStyle(by: .value("Series", "Variation Max"))

                LineMark(
                    x: .value("Time", value.plotTime!, unit: .minute),
                    y: .value("Speed", value.windAvg!.doubleValue)
                )
            }
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: Array(plots)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Image(systemName: "arrow.down")
                        .rotationEffect(.degrees(plots[value.index].windDir!.doubleValue))
                }
            }
        }
        .chartYAxisLabel("m/s")
        .chartForegroundStyleScale([
            "Average": Color("AccentColor"),
            "Variation": Color("AccentColor").opacity(0.1),
            "Variation Min": Color("AccentColor").opacity(0.2),
            "Variation Max": Color("AccentColor").opacity(0.2),
        ])
        .chartLegend(.hidden)
    }
}
