//
//  NSDate+RelativeDate.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 27.08.15.
//  Copyright © 2015 RHC. All rights reserved.
//

import Foundation


extension Date {

    public func releativeString() -> String {
        let bundle = AppConfig.sharedConfiguration.frameworkBundle
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let components = (calendar as NSCalendar).components([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: self, to: now, options: [])

        if components.year! >= 1 {
            if components.year == 1 {
                return NSLocalizedString("1 year ago", tableName: nil, bundle: bundle, value: "1 year ago", comment:"1 year ago")
            }
            return String.localizedStringWithFormat(NSLocalizedString("%d years ago", tableName: nil, bundle: bundle, value: "", comment: "Years ago"), components.year!)
        } else if components.month! >= 1 {
            if components.month == 1 {
                return NSLocalizedString("1 month ago", tableName: nil, bundle: bundle, value: "1 month ago", comment:"1 month ago")
            }
            return String.localizedStringWithFormat(NSLocalizedString("%d months ago", tableName: nil, bundle: bundle, value: "", comment: "Months ago"), components.month!)
        } else if components.weekOfYear! >= 1 {
            if components.weekOfYear == 1 {
                return NSLocalizedString("1 week ago", tableName: nil, bundle: bundle, value: "1 week ago", comment:"1 week ago")
            }
            return String.localizedStringWithFormat(NSLocalizedString("%d weeks ago", tableName: nil, bundle: bundle, value: "", comment: "Weeks ago"), components.weekOfYear!)
        } else if components.day! >= 1 {    // up to 6 days ago
            if components.day == 1 {
                return NSLocalizedString("1 day ago", tableName: nil, bundle: bundle, value: "1 day ago", comment:"1 day ago")
            }
            return String.localizedStringWithFormat(NSLocalizedString("%d days ago", tableName: nil, bundle: bundle, value: "Days ago", comment: "Days ago"), components.day!)
        } else if components.hour! >= 1 {   // up to 23 hours ago
            if components.hour == 1 {
                return NSLocalizedString("An hour ago", tableName: nil, bundle: bundle, value: "An hour ago", comment:"An hour ago")
            }
            return String.localizedStringWithFormat(NSLocalizedString("%d hours ago", tableName: nil, bundle: bundle, value: "", comment: "Hours ago"), components.hour!)
        } else if components.minute! >= 1 { // up to 59 minutes ago
            if components.minute == 1 {
                return NSLocalizedString("A minute ago", tableName: nil, bundle: bundle, value: "A minute ago", comment:"A minute ago")
            }
            return String.localizedStringWithFormat(NSLocalizedString("%d minutes ago", tableName: nil, bundle: bundle, value: "", comment: "Minutes ago"), components.minute!)
        } else if components.second! < 5 {
            return NSLocalizedString("Just now", tableName: nil, bundle: bundle, value: "Just now", comment:"Just now")
        }

        // between 5 and 59 seconds ago
        return String.localizedStringWithFormat(NSLocalizedString("%d seconds ago", tableName: nil, bundle: bundle, value: "", comment: "Seconds ago"), components.second!)
    }
}
