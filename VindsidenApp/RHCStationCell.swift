//
//  RHCStationCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 12/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import UIKit
import OSLog
import SwiftUI
import VindsidenKit
import Units

@objc
class RHCStationCell: UICollectionViewCell {
    @ObservedObject var observer: PlotObservable = PlotObservable()

    override init(frame: CGRect) {
        fatalError("Not implemented")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupView()
    }

    func setupView() {
//        @ObservedObject
//        var settings = (UIApplication.shared.delegate as? RHCAppDelegate)!.settings

        contentConfiguration = UIHostingConfiguration(content: {
            StationView(observer: observer, updater: displayPlots)
//                .environmentObject(settings)
                .environment(\.managedObjectContext, DataManager.shared.viewContext())
        })
    }

    @objc
    weak var currentStation: CDStation? {
        didSet {
            guard let station = currentStation else {
                return
            }

            observer.station = station

            displayPlots()
        }
    }

    @objc
    func displayPlots() {
        DispatchQueue.main.async { [weak self] in
            self?.syncDisplayPlots()
        }
    }

    private func syncDisplayPlots() {
        guard
            let gregorian = NSCalendar(identifier: .gregorian),
            let currentStation,
            let context = currentStation.managedObjectContext
        else {
            return
        }

        let inDate = Date().addingTimeInterval(-1*AppConfig.Global.plotHistory*3600)
        let inputComponents = gregorian.components([.year, .month, .day, .hour], from: inDate)
        let outDate = gregorian.date(from: inputComponents) ?? Date()

        let fetchRequest = CDPlot.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "station == %@ AND plotTime >= %@", currentStation, outDate as CVarArg)
        fetchRequest.fetchLimit = 35
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "plotTime", ascending: false),
        ]

        let cdplots: [CDPlot] = (try? context.fetch(fetchRequest)) ?? []

        observer.plot = cdplots.first
        observer.plots = cdplots
    }
}
