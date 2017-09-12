//
//  Logger.swift
//  TechDemo
//
//  Created by Ragnar Henriksen on 10/12/14.
//  Copyright (c) 2014 Ragnar Henriksen. All rights reserved.
//

import Foundation

@objc(Logger)
open class Logger : NSObject {
    open class func DLOG( _ message: String, file: String = #file, function: String = #function, line: Int = #line ) {
        #if Debug
            NSLog("([\((file as NSString).lastPathComponent) \(function)] line: \(line)) \(message)")
        #endif
    }


    open class func LOG( _ message: String) {
        #if Debug
            NSLog("\(message)")
        #endif
    }


    open class func WARNING( _ message: String, file: String = #file, function: String = #function, line: Int = #line ) {
        NSLog("([\((file as NSString).lastPathComponent) \(function)] line: \(line)) \(message)")
    }
}
