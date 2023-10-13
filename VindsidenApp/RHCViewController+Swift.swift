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

extension RHCViewController: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        guard let cell = collectionView.visibleCells.first as? RHCStationCell, let station = cell.currentStation else {
            return nil
        }

        let actionProvider: UIContextMenuActionProvider = { (suggestedActions: [UIMenuElement]) -> UIMenu? in
            var actions = [UIAction]()

            if let yrURL = station.yrURL?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                let yr = UIAction(title: NSLocalizedString("Go to yr.no", comment: ""), image: UIImage(systemName: "wind"), identifier: nil) { handler in
                    guard let url = URL(string: yrURL) else {
                        return
                    }

                    UIApplication.shared.open(url, options: [:]) { (success) in
                        Logger.debugging.debug("Opened successfully \(success)")
                    }
                }

                actions.append(yr)
            }

            let maps = UIAction(title: NSLocalizedString("View in Maps", comment: ""), image: UIImage(systemName: "mappin.and.ellipse"), identifier: nil) { handler in
                let spotCord = station.coordinate

                var query = "http://maps.apple.com/?t=h&z=10"

                if spotCord.latitude > 0 || spotCord.longitude > 0 {
                    query += "&ll=\(spotCord.latitude),\(spotCord.longitude)"
                }

                if let city = station.city, !city.isEmpty {
                    query += "&q=\(city)"
                } else if let stationName = station.stationName {
                    query += "&q=\(stationName)"
                }

                guard let mapurl = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed), let url = URL(string: mapurl) else {
                    return
                }

                UIApplication.shared.open(url, options: [:]) { (success) in
                    Logger.debugging.debug("Opened successfully \(success)")
                }
            }

            actions.append(maps)

            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: actions)
        }

        let infoController: UIContextMenuContentPreviewProvider = { [weak self] in
            guard let viewcontroller = self?.storyboard?.instantiateViewController(identifier: "infoViewPresenter") as? UINavigationController else {
                return nil
            }

            if let controller = viewcontroller.topViewController as? RHEStationDetailsViewController, let cell = self?.collectionView.visibleCells.first as? RHCStationCell {
                controller.delegate = self as? RHEStationDetailsDelegate
                controller.station = cell.currentStation
            }
            
            viewcontroller.setNavigationBarHidden(true, animated: false)
            return viewcontroller
        }

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: infoController,
                                          actionProvider: actionProvider)
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [weak self] in
            self?.performSegue(withIdentifier: "ShowStationDetails", sender: nil)
        }
    }
}

extension RHCViewController {
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
}

