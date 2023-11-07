//
//  UserObservable.swift
//  VindsidenKit
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import SwiftUI
import Units

@Observable
public class UserObservable {
    public var windUnit: WindUnit {
        didSet {
            UserSettings.shared.selectedWindUnit = windUnit
            self.lastChanged = Date()
        }
    }

    public var tempUnit: TempUnit {
        didSet {
            UserSettings.shared.selectedTempUnit = tempUnit
            self.lastChanged = Date()
        }
    }

    public var selectedStationId: String? {
        didSet {
            UserSettings.shared.selectedStationId = selectedStationId
            self.lastChanged = Date()
        }
    }

    public var lastChanged: Date

    public init() {
        self.windUnit = UserSettings.shared.selectedWindUnit
        self.tempUnit = UserSettings.shared.selectedTempUnit
        self.selectedStationId = UserSettings.shared.selectedStationId
        self.lastChanged = Date()
    }

    public func updateFromApplicationContext(_ context: [String: Any]) {
        DispatchQueue.main.async {
            if let value = context[CodingUserInfoKey.windUnit.rawValue] as? Int, let unit = WindUnit(rawValue: value) {
                self.windUnit = unit
            }

            if let value = context[CodingUserInfoKey.tempUnit.rawValue] as? Int, let unit = TempUnit(rawValue: value) {
                self.tempUnit = unit
            }
        }
    }
}

public final class UserSettings {
    @UserSetting(defaultValue: .metersPerSecond, storageKey: "selectedWindUnit")
    public var selectedWindUnit: WindUnit

    @UserSetting(defaultValue: .celsius, storageKey: "selectedTempUnit")
    public var selectedTempUnit: TempUnit

    @UserSetting(defaultValue: nil, storageKey: "selectedStationId")
    public var selectedStationId: String?

    public static var shared = UserSettings()

    private init() { }
}


public extension UserSettings {
    @propertyWrapper
    struct UserSetting<T: Codable> {
        var defaultValue: T
        var storageKey: String

        private static var applicationGroup: String {
            return AppConfig.ApplicationGroups.primary
        }

        private static var userDefaults: UserDefaults {
            let userDefaults = UserDefaults(suiteName: applicationGroup)!
            return userDefaults
        }

        public var wrappedValue: T {
            get {
                guard let data = Self.userDefaults.data(forKey: storageKey) else {
                    return defaultValue
                }

                do {
                    let res = try JSONDecoder().decode(T.self, from: data)
                    return res
                } catch {
                    return defaultValue
                }
            }
            set {
                do {
                    let res = try JSONEncoder().encode(newValue)
                    Self.userDefaults.set(res, forKey: storageKey)
                } catch {
                    print("Failed to set: \(error)")
                }
            }
        }
    }
}
