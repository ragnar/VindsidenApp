//
//  Logger.swift
//  TechDemo
//
//  Created by Ragnar Henriksen on 10/12/14.
//  Copyright (c) 2014 Ragnar Henriksen. All rights reserved.
//

import Foundation

@objc(Logger)
public class Logger : NSObject {
    public class func DLOG( message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__ ) {
        #if Debug
            NSLog("([\((file as NSString).lastPathComponent) \(function)] line: \(line)) \(message)")
        #endif
    }


    public class func LOG( message: String) {
        #if Debug
            NSLog("\(message)")
        #endif
    }


    public class func WARNING( message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__ ) {
        NSLog("([\((file as NSString).lastPathComponent) \(function)] line: \(line)) \(message)")
    }
}
