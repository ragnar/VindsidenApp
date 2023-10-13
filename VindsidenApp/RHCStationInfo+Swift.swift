//
//  RHCStationInfo+Swift.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 13/10/2023.
//  Copyright © 2023 RHC. All rights reserved.
//

import Foundation
import Units
import VindsidenKit

fileprivate let speedFormatter: NumberFormatter = {
    let _speedFormatter = NumberFormatter()
    _speedFormatter.numberStyle = NumberFormatter.Style.decimal
    _speedFormatter.maximumFractionDigits = 1
    _speedFormatter.minimumFractionDigits = 1
    _speedFormatter.notANumberSymbol = "—"
    _speedFormatter.nilSymbol = "—"

    return _speedFormatter
}()


extension RHCStationInfo {
    @objc
    func tempString(value: Double) -> String {
        let unit = UserObservable().tempUnit
        let converted = value.toUnit(unit)
        let string = speedFormatter.string(from: NSNumber(floatLiteral: converted)) ?? "-.-"

        return "\(string) \(unit.symbol)"
    }

    @objc
    func windString(value: Double) -> String {
        let unit = UserObservable().windUnit
        let converted = value.fromUnit(.metersPerSecond).toUnit(unit)
        let string = speedFormatter.string(from: NSNumber(floatLiteral: converted)) ?? "-.-"

        return "\(string) \(unit.symbol)"
    }
}
