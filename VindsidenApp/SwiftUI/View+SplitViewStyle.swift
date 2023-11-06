//
//  View+SplitViewStyle.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 06/11/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    public func currentDeviceNavigationSplitViewStyle() -> some View {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            self.navigationSplitViewStyle(BalancedNavigationSplitViewStyle())

        case .mac:
            self.navigationSplitViewStyle(BalancedNavigationSplitViewStyle())

        default:
            self.navigationSplitViewStyle(AutomaticNavigationSplitViewStyle())
        }
    }
}
