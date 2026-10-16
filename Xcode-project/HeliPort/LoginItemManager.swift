//
//  LoginItemManager.swift
//  HeliPort
//
//  Created by Bat.bat on 7/14/20.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation
import ServiceManagement

class LoginItemManager {
    private static let mainAppService = SMAppService.mainApp

    class func isEnabled() -> Bool {
        mainAppService.status == .enabled
    }

    class func setStatus(enabled: Bool) {
        do {
            if enabled {
                try mainAppService.register()
            } else {
                try mainAppService.unregister()
            }
        } catch {
            print("Failed to update launch-at-login status: \(error.localizedDescription)")
        }
    }
}
