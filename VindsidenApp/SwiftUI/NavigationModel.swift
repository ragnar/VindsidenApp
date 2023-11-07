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
    var pendingSelectedStationId: Int?
    var columnVisibility: NavigationSplitViewVisibility

    init(pendingSelectedStationId: Int? = nil, columnVisibility: NavigationSplitViewVisibility = .all) {
        self.pendingSelectedStationId = pendingSelectedStationId
        self.columnVisibility = columnVisibility
    }
}
