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

    fileprivate static let prefix: String = {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        return bundleIdentifier + "."
    }()

    init?(prefixedString: String) {
        guard let prefixRange = prefixedString.range(of: ShortcutItemType.prefix) else {
            return nil
        }

        var rawTypeString = prefixedString
        rawTypeString.removeSubrange(prefixRange)
        self.init(rawValue: rawTypeString)
    }

    var prefixedString: String {
        return type(of: self).prefix + self.rawValue
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
            dictionary[ShortcutItemUserInfo.stationIdentifierKey] = stationIdentifier as NSSecureCoding?
        }
        return dictionary
    }
}

struct ShortcutItemHandler {

    static func updateDynamicShortcutItems(for application: UIApplication) {
        DataManager.shared.performBackgroundTask { (context) in
            let stations = CDStation.visibleStationsInManagedObjectContext(context, limit: 4)
            var shortcutItems = [UIApplicationShortcutItem]()

            for station in stations {
                let type = ShortcutItemType.goToStation
                guard let stationId = station.stationId,
                    let title = station.stationName,
                    let subtitle = station.city else {
                    continue
                }

                let userInfo = ShortcutItemUserInfo(stationIdentifier: "\(stationId)")
                let shortcutItem = UIApplicationShortcutItem(type: type.prefixedString, localizedTitle: title, localizedSubtitle: subtitle, icon: nil, userInfo:userInfo.dictionaryRepresentation)
                shortcutItems.append(shortcutItem)
            }

            application.shortcutItems = shortcutItems
        }
    }

    static func handle(_ shortcutItem: UIApplicationShortcutItem, with rootViewController: RHCViewController) -> Bool {

        guard let shortcutItemType = ShortcutItemType(prefixedString: shortcutItem.type) else {
            return false
        }

        let station: CDStation?

        switch shortcutItemType {
        case .goToStation:
            let userInfo = ShortcutItemUserInfo(dictionaryRepresentation: shortcutItem.userInfo)
            if let stationIdentifier = userInfo.stationIdentifier, let stationId = Int(stationIdentifier)  {
                station = try? CDStation.existingStationWithId(stationId, inManagedObjectContext: DataManager.shared.viewContext())
            } else {
                station = nil
            }
        }

        if let station = station {
            rootViewController.scroll(to: station)
            return true
        }
        return false
    }
}
