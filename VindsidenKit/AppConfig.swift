//
//  AppConfig.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15/12/14.
//  Copyright (c) 2014 Ragnar Henriksen. All rights reserved.
//

import Foundation


@objc(AppConfig)
public class AppConfig : NSObject {
    private struct Defaults {
        static let firstLaunchKey = "Defaults.firstLaunchKey"
        private static let spotlightIndexed = "Defaults.spotlightIndexed"
    }


    public struct Global {
        static let plotHistory = 5.0
    }


    public struct Notification {
        public static let networkRequestStart = Bundle.prefix + "." + Bundle.appName + ".NetworkRequestStart"
        public static let networkRequestEnd = Bundle.prefix + "." + Bundle.appName + ".NetworkRequestEnd"
    }


    public struct Bundle {
        static var prefix = "org.juniks" // Could be done automatic by reading info.plist
        static let appName = "VindsidenApp" // Could be done automatic by reading info.plist
        static let todayName = "VindsidenToday"
        static let watchName = "Watch"
        #if os(iOS)
        public static let frameworkBundleIdentifier = "\(prefix).VindsidenKit"
        #else
        public static let frameworkBundleIdentifier = "\(prefix).VindsidenWatchKit"
        #endif
    }


    struct ApplicationGroups {
        static let primary = "group.\(Bundle.prefix).\(Bundle.appName)"
    }


    public struct Extensions {
        public static let widgetBundleIdentifier = "\(Bundle.prefix).\(Bundle.appName).\(Bundle.todayName)"
        public static let watchBundleIdentifier = "\(Bundle.prefix).\(Bundle.appName).\(Bundle.watchName)"
    }


    public struct CoreData {
        public static let datamodelName = "Vindsiden"
        public static let sqliteName = "\(datamodelName).sqlite"
    }


    public struct Error {
        public static let domain = "\(Bundle.prefix).\(Bundle.appName)"
    }

    
    public class var sharedConfiguration: AppConfig {
        struct Singleton {
            static let sharedAppConfiguration = AppConfig()
        }

        return Singleton.sharedAppConfiguration
    }


    public var applicationUserDefaults: NSUserDefaults {
        return NSUserDefaults(suiteName: ApplicationGroups.primary)!
    }


    public lazy var frameworkBundle: NSBundle! = {
        return NSBundle(identifier: Bundle.frameworkBundleIdentifier)
    }()


    public lazy var applicationDocumentsDirectory: NSURL? = {
        let urlOrNil = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(ApplicationGroups.primary)
        if let url = urlOrNil {
            return url as NSURL
        } else {
            return NSURL()
        }
    }()


    public private(set) var isFirstLaunch: Bool {
        get {
            registerDefaults()
            return applicationUserDefaults.boolForKey(Defaults.firstLaunchKey)
        }
        set {
            applicationUserDefaults.setBool(newValue, forKey: Defaults.firstLaunchKey)
        }
    }


    public private(set) var isSpotlightIndexed: Bool {
        get {
            return applicationUserDefaults.boolForKey(Defaults.spotlightIndexed)
        }
        set {
            applicationUserDefaults.setBool(newValue, forKey: Defaults.spotlightIndexed)
        }
    }


    private func registerDefaults() {
        #if os(watchOS)
            let defaultOptions: [String: AnyObject] = [
            Defaults.firstLaunchKey: true,
            ]
        #elseif os(iOS)
            let defaultOptions: [String: AnyObject] = [
                Defaults.firstLaunchKey: true,
            ]
            #elseif os(OSX)
            let defaultOptions: [String: AnyObject] = [
            Defaults.firstLaunchKey: true
            ]
        #endif

        applicationUserDefaults.registerDefaults(defaultOptions)
    }


    public func runHandlerOnFirstLaunch(firstLaunchHandler: Void -> Void) {
        if isFirstLaunch {
            isFirstLaunch = false

            firstLaunchHandler()
        }
    }


    public func shouldIndexForFirstTime( completionHandler: Void -> Void) {
        if isSpotlightIndexed == false {
            isSpotlightIndexed = true
            completionHandler()
        }
    }


    public func relativeDate( dateOrNil: NSDate?) -> NSString {
        var dateToUse: NSDate

        if let date = dateOrNil {
            dateToUse = date.earlierDate(NSDate())
        } else {
            dateToUse = NSDate()
        }

        return dateToUse.releativeString()
    }
}
