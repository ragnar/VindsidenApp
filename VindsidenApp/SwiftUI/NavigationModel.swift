//
//  NavigationModel.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 03/11/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import OSLog
import VindsidenKit

@MainActor
@Observable
class NavigationModel {
    var pendingSelectedStationName: String?
    var columnVisibility: NavigationSplitViewVisibility

    init(pendingSelectedStationName: String? = nil, columnVisibility: NavigationSplitViewVisibility = .all) {
        self.pendingSelectedStationName = pendingSelectedStationName
        self.columnVisibility = columnVisibility
    }
}
