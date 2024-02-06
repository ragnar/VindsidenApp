//
//  VindsidenWidget.swift
//  VindsidenWidget
//
//  Created by Ragnar Henriksen on 11/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import WidgetKit
import SwiftUI
import WeatherBoxView

#if os(watchOS)
import VindsidenWatchKit
#else
import VindsidenKit
#endif

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastDate: Date
    let configuration: ConfigurationAppIntent
    let plots: [Plot]
}

struct SinglePlotEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let widgetData: WidgetData
}
