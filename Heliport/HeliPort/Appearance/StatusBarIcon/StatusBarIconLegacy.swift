//
//  StatusBarIconLegacy.swift
//  HeliPort
//
//  Created by Bat.bat on 25/6/2024.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa

class StatusBarIconLegacy: StatusBarIconProvider {
    var transition: CATransition? {
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.2
        return transition
    }
    var off: NSImage { return NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "WiFi Off")! }
    var connected: NSImage { return NSImage(systemSymbolName: "wifi", accessibilityDescription: "WiFi On")! }
    var disconnected: NSImage {
        return NSImage(systemSymbolName: "wifi", accessibilityDescription: "WiFi Disconnected")!
    }
    var warning: NSImage {
        return NSImage(systemSymbolName: "wifi.exclamationmark", accessibilityDescription: "WiFi Warning")!
    }
    var scanning: [NSImage] {
        return [
            NSImage(systemSymbolName: "wifi", accessibilityDescription: "Scanning")!,
            NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "Scanning")!
        ]
    }

    func getRssiImage(_ RSSI: Int16) -> NSImage? {
        let normalized = Double(max(min(RSSI + 100, 70), 0)) / 70.0
        return NSImage(systemSymbolName: "wifi", variableValue: normalized, accessibilityDescription: "Signal Strength")
    }
}
