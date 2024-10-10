//
//  Logger.swift
//  TechDemo
//
//  Created by Ragnar Henriksen on 10/12/14.
//  Copyright (c) 2014 Ragnar Henriksen. All rights reserved.
//

import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!

    public static let debugging = Logger(subsystem: subsystem, category: "debug")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    public static let wind = Logger(subsystem: subsystem, category: "wind")
    public static let fetcher = Logger(subsystem: subsystem, category: "fetcher")
    public static let windManager = Logger(subsystem: subsystem, category: "windmanager")
    public static let resource = Logger(subsystem: subsystem, category: "resource")
}
