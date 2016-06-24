//
//  ShortcutItemHandling.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 23.06.2016.
//  Copyright © 2016 RHC. All rights reserved.
//

import UIKit
import VindsidenKit

enum ShortcutItemType: String {
    case goToStation

    private static let prefix: String = {
        let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier!
        return bundleIdentifier + "."
    }()

    init?(prefixedString: String) {
        guard let prefixRange = prefixedString.rangeOfString(ShortcutItemType.prefix) else {
            return nil
        }

        var rawTypeString = prefixedString
        rawTypeString.removeRange(prefixRange)
        self.init(rawValue: rawTypeString)
    }

    var prefixedString: String {
        return self.dynamicType.prefix + self.rawValue
    }
}

struct ShortcutItemUserInfo {
    static let stationIdentifierKey = "stationIdentifier"
    var stationIdentifier: String?

    init(stationIdentifier: String? = nil) {
        self.stationIdentifier = stationIdentifier
    }

    init(dictionaryRepresentation: [String : NSSecureCoding]?) {
        guard let dictionary = dictionaryRepresentation else { return }
        self.stationIdentifier = dictionary[ShortcutItemUserInfo.stationIdentifierKey] as? String
    }

    var dictionaryRepresentation: [String : NSSecureCoding] {
        var dictionary: [String : NSSecureCoding] = [:]
        if let stationIdentifier = stationIdentifier {
            dictionary[ShortcutItemUserInfo.stationIdentifierKey] = stationIdentifier
        }
        return dictionary
    }
}

struct ShortcutItemHandler {

    static func updateDynamicShortcutItems(for application: UIApplication) {
        var shortcutItems = [UIApplicationShortcutItem]()

        let stations = CDStation.visibleStationsInManagedObjectContext(Datamanager.sharedManager().managedObjectContext, limit: 4)

        for station in stations {
            let type = ShortcutItemType.goToStation
            let title = station.stationName!
            let subtitle = station.city!

            let userInfo = ShortcutItemUserInfo(stationIdentifier: "\(station.stationId!)")
            let shortcutItem = UIApplicationShortcutItem(type: type.prefixedString, localizedTitle: title, localizedSubtitle: subtitle, icon: nil, userInfo:userInfo.dictionaryRepresentation)
            shortcutItems.append(shortcutItem)
        }

        application.shortcutItems = shortcutItems
    }

    static func handle(shortcutItem: UIApplicationShortcutItem, with rootViewController: RHCViewController) -> Bool {

        guard let shortcutItemType = ShortcutItemType(prefixedString: shortcutItem.type) else {
            return false
        }

        let station: CDStation?

        switch shortcutItemType {
        case .goToStation:
            let userInfo = ShortcutItemUserInfo(dictionaryRepresentation: shortcutItem.userInfo)
            if let stationIdentifier = userInfo.stationIdentifier, let stationId = Int(stationIdentifier)  {
                station = try? CDStation.existingStationWithId(stationId, inManagedObjectContext: Datamanager.sharedManager().managedObjectContext)
            }
            else {
                station = nil
            }

        }

        if let station = station {
            rootViewController.scrollToStation(station)
            return true
        }
        return false
    }
}
