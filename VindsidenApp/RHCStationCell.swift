//
//  RHCStationCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import UIKit
import VindsidenKit


@objc
class RHCStationCell: UICollectionViewCell {
    @IBOutlet weak var stationNameLabel: UILabel?
    @IBOutlet weak var updatedAtLabel: UILabel?
    @IBOutlet weak var cameraButton: UIButton?
    @IBOutlet weak var graphView: RHEGraphView?
    @IBOutlet weak var stationView: RHCStationInfo?

    @objc
    weak var currentStation: CDStation? {
        didSet {
            guard let station = currentStation else {
                return
            }

            stationNameLabel?.text = station.stationName
            graphView?.copyright = station.copyright

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
        graphView?.copyright = nil
        graphView?.plots = nil
        stationView?.resetInfoLabels()
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
            graphView?.copyright = currentStation.copyright
            graphView?.plots = cdplots
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
