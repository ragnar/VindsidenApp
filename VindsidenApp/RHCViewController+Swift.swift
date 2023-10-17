//
//  RHCViewController+Swift.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 24/09/2019.
//  Copyright © 2019 RHC. All rights reserved.
//

import UIKit
import SwiftUI
import OSLog
import VindsidenKit

extension RHCViewController {
    @objc
    func fetchStations() {
        Task {
            do {
                let stations = try await StationFetcher().fetch()
                updateStations(stations)
                saveActivity()
            } catch {
                RHCAlertManager.defaultManager.showNetworkError(error as NSError)
            }
        }
    }

    @objc
    func openSettings() {
        let root = UIHostingController(rootView: SettingsView(dismissAction: {
            Logger.debugging.debug("Settings Dismissed")
            
            self.updateApplicationContextToWatch()
            (UIApplication.shared.delegate as? RHCAppDelegate)?.updateShortcutItems()
            WindManager.sharedManager.updateNow()

            if let cell = self.collectionView.visibleCells.first as? RHCStationCell {
                cell.displayPlots()
            }
        })
            .environmentObject((UIApplication.shared.delegate as? RHCAppDelegate)!.settings)
            .environment(\.managedObjectContext, DataManager.shared.viewContext())
        )

        navigationController?.present(root, animated: true)
    }

    @objc
    func openStationDetails() {
        guard let cell = self.collectionView.visibleCells.first as? RHCStationCell else {
            return
        }

        let root = UIHostingController(rootView: StationDetailsView(station: cell.currentStation!))
        navigationController?.present(root, animated: true)
    }
}

