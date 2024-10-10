//
//  AppConfig.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 15/12/14.
//  Copyright (c) 2014 Ragnar Henriksen. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
import StoreKit
#endif


//@objc(AppConfig)
public final class AppConfig : NSObject, @unchecked Sendable {
    fileprivate struct Defaults {
        static let firstLaunchKey = "Defaults.firstLaunchKey"
        fileprivate static let spotlightIndexed = "Defaults.spotlightIndexed"
        fileprivate static let bootCount = "Defaults.bootCount"
    }


    public struct Global {
        public static let plotHistory = 5.0
    }

    public struct Bundle {
        static let prefix = "org.juniks" // Could be done automatic by reading info.plist
        static let appName = "VindsidenApp" // Could be done automatic by reading info.plist
        static let todayName = "VindsidenToday"
        static let watchName = "Watch"
        #if os(iOS)
        public static let frameworkBundleIdentifier = "\(prefix).VindsidenKit"
        #else
        public static let frameworkBundleIdentifier = "\(prefix).VindsidenWatchKit"
        #endif
    }


    public struct ApplicationGroups {
        public static let primary = "group.\(Bundle.prefix).\(Bundle.appName)"
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

    public static let shared = AppConfig()

    @objc public var applicationUserDefaults: UserDefaults {
        return UserDefaults(suiteName: ApplicationGroups.primary)!
    }


    public lazy var frameworkBundle: Foundation.Bundle = {
        return Foundation.Bundle(identifier: Bundle.frameworkBundleIdentifier)!
    }()

    public lazy var applicationDocumentsDirectory: URL? = {
        let urlOrNil = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ApplicationGroups.primary)
        if let url = urlOrNil {
            return url as URL
        } else {
            return nil
        }
    }()

    public fileprivate(set) var isFirstLaunch: Bool {
        get {
            registerDefaults()
            return applicationUserDefaults.bool(forKey: Defaults.firstLaunchKey)
        }
        set {
            applicationUserDefaults.set(newValue, forKey: Defaults.firstLaunchKey)
        }
    }

    public fileprivate(set) var isSpotlightIndexed: Int {
        get {
            return applicationUserDefaults.integer(forKey: Defaults.spotlightIndexed)
        }
        set {
            applicationUserDefaults.set(newValue, forKey: Defaults.spotlightIndexed)
        }
    }

    fileprivate func registerDefaults() {
        #if os(watchOS)
            let defaultOptions: [String: AnyObject] = [
            Defaults.firstLaunchKey: true as AnyObject,
            ]
        #elseif os(iOS)
            let defaultOptions: [String: AnyObject] = [
                Defaults.firstLaunchKey: true as AnyObject,
            ]
            #elseif os(OSX)
            let defaultOptions: [String: AnyObject] = [
            Defaults.firstLaunchKey: true
            ]
        #endif

        applicationUserDefaults.register(defaults: defaultOptions)
    }

    public func runHandlerOnFirstLaunch(_ firstLaunchHandler: () -> Void) {
        if isFirstLaunch {
            isFirstLaunch = false

            firstLaunchHandler()
        }
    }

    public func shouldIndexForFirstTime() -> Bool {
        if isSpotlightIndexed < 2 {
            isSpotlightIndexed = 2
            return true
        }

        return false
    }

    // MARK: - Review

#if os(iOS)
    public func presentReviewControllerIfCriteriaIsMet(in scene: UIWindowScene) {
        defer {
            applicationUserDefaults.synchronize()
        }

        let version = (Foundation.Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)

        guard let bootCount = applicationUserDefaults.dictionary(forKey: Defaults.bootCount) as? [String:Int] else {
            applicationUserDefaults.set([version: 1], forKey: Defaults.bootCount)
            return
        }

        guard let count = bootCount[version] else {
            applicationUserDefaults.set([version: 1], forKey: Defaults.bootCount)
            return
        }

        applicationUserDefaults.set([version: count + 1], forKey: Defaults.bootCount)

        if count % 5 == 0 {
            applicationUserDefaults.set([version: 1], forKey: Defaults.bootCount)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
#endif
}
