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

    @IBAction func settings(_ sender: Any) {
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


    @IBAction func info(_ sender: Any) {
        guard
            let cell = self.collectionView.visibleCells.first as? RHCStationCell,
            let currentStation = cell.currentStation
        else {
            return
        }

        let root = UIHostingController(rootView: StationDetailsView(station: currentStation))
        navigationController?.present(root, animated: true)
    }

    @IBAction func camera(_ sender: Any) {
        guard
            let cell = self.collectionView.visibleCells.first as? RHCStationCell,
            let webCamURL = cell.currentStation?.webCamImage,
            let url = URL(string: webCamURL)
        else {
            return
        }

        Logger.debugging.debug("Webcam: \(url)")

        var photoView = PhotoView(imageUrl: url)
        let rootView = photoView
            .edgesIgnoringSafeArea(.all)
            .modifier(RotateOnDragModifier())
            .modifier(SwipeToDismissModifier(
                onDismiss: {
                    defer {
                        self.dismiss(animated: false)
                    }

                    guard let backgroundView = photoView.backgroundView else {
                        return
                    }

                    photoView.opacity = 0.0
                    backgroundView.backgroundColor = .clear
                },
                onChange: { percent in
                    guard let backgroundView = photoView.backgroundView else {
                        return
                    }

                    backgroundView.backgroundColor = .black.withAlphaComponent(percent)
                }
            ))

        let controller = UIHostingController(rootView: rootView)
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        controller.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        controller.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPhoto(_:))))
        photoView.backgroundView = controller.view

        navigationController?.present(controller, animated: true)
    }

    @objc
    func dismissPhoto(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

