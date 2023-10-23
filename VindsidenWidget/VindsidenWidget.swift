//
//  VindsidenWidget.swift
//  VindsidenWidget
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Charts
import VindsidenKit
import WeatherBoxView

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let plots: [Plot]
}

struct SinglePlotEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let widgetData: WidgetData
}
