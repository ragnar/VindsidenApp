//
//  Logger.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 04/02/15.
//  Copyright (c) 2015 RHC. All rights reserved.
//

import Foundation

public func DLOG( message: String, file: String = #file, function: String = #function, line: Int = #line ) {
    #if Debug
        NSLog("([\((file as NSString).lastPathComponent) \(function)] line: \(line)) %@", message)
    #endif
}


public func LOG( message: String) {
    #if Debug
        NSLog("%@", message)
    #endif
}


public func WARNING( message: String, file: String = #file, function: String = #function, line: Int = #line ) {
    NSLog("([\((file as NSString).lastPathComponent) \(function)] line: \(line)) %@", message)
}