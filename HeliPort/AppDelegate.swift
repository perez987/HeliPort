//
//  AppDelegate.swift
//  HeliPort
//
//  Created by 梁怀宇 on 2020/3/20.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {

    public var updaterController: SPUStandardUpdaterController?
    private let updaterDelegate = SparkleDelegate()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        checkRunPath()
        checkAPI()

        // Initialize Sparkle
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: nil
        )
        self.updaterController = controller

        let statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let iconProvider = StatusBarIconModern()
        _ = StatusBarIcon.shared(statusBar: statusBar, icons: iconProvider)

        statusBar.menu = StatusMenuModern()

        promptForLaunchAtLogin()
        scheduleAutoQuitIfNeeded()
    }

    private var driverInfo = ioctl_driver_info()

    private func checkDriver() -> Bool {

        _ = ioctl_get(Int32(IOCTL_80211_DRIVER_INFO.rawValue), &driverInfo, MemoryLayout<ioctl_driver_info>.size)

        let version = String(cCharArray: driverInfo.driver_version)
        let interface = String(cCharArray: driverInfo.bsd_name)
        guard !version.isEmpty, !interface.isEmpty else {
            print("itlwm kext not loaded!")
#if !DEBUG
            let alert = CriticalAlert(message: NSLocalizedString("itlwm is not running"),
                                      options: [NSLocalizedString("Dismiss"),
                                                NSLocalizedString("Quit HeliPort")])

            if alert.show() == .alertSecondButtonReturn {
                NSApp.terminate(nil)
            }

#endif
            return false
        }

        print("Loaded itlwm \(version) as \(interface)")

        return true
    }

    // Due to macOS App Translocation, users must store this app in /Applications
    // Otherwise Sparkle and "Launch At Login" will not function correctly
    // Ref: https://lapcatsoftware.com/articles/app-translocation.html
    private func checkRunPath() {
        let pathComponents = (Bundle.main.bundlePath as NSString).pathComponents

#if DEBUG
        // Normal users should never use the Debug Version
        guard pathComponents[pathComponents.count - 2] != "Debug" else {
            return
        }
#else
        guard pathComponents[pathComponents.count - 2] != "Applications" else {
            return
        }
#endif

        print("Running path unexpected!")

        let alert = CriticalAlert(
            message: NSLocalizedString("HeliPort running at an unexpected path"),
            informativeText: NSLocalizedString(
                "Moving HeliPort to the Applications folder is recommended for full functionality."
            ),
                                  options: [NSLocalizedString("Continue Anyway"),
                                            NSLocalizedString("Quit HeliPort")]
        )

        if alert.show() == .alertSecondButtonReturn {
            NSApp.terminate(nil)
        }
    }

    private func promptForLaunchAtLogin() {
        guard !UserDefaults.standard.bool(forKey: .DefaultsKey.hasPromptedForLaunchAtLogin) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Launch HeliPort at Login?")
            alert.informativeText = NSLocalizedString(
                "Would you like HeliPort to start automatically when you log in to your Mac?"
            )
            alert.addButton(withTitle: NSLocalizedString("Enable"))
            alert.addButton(withTitle: NSLocalizedString("Not Now"))
            alert.alertStyle = .informational

            if alert.runModal() == .alertFirstButtonReturn {
                LoginItemManager.setStatus(enabled: true)
                print("User enabled Launch at Login via first-run prompt")
            }

            UserDefaults.standard.set(true, forKey: .DefaultsKey.hasPromptedForLaunchAtLogin)
        }
    }

    private func checkAPI() {

        // It's fine for users to bypass this check by launching HeliPort first then loading itlwm in terminal
        // Only advanced users do so, and they know what they are doing
        guard checkDriver(), IOCTL_VERSION != driverInfo.version else {
            return
        }

        print("itlwm API mismatch!")

#if !DEBUG
        let text = NSLocalizedString("HeliPort API Version: ") + String(IOCTL_VERSION) +
                   "\n" + NSLocalizedString("itlwm API Version: ") + String(driverInfo.version)
        let alert = CriticalAlert(message: NSLocalizedString("itlwm Version Mismatch"),
                                  informativeText: text,
                                  options: [NSLocalizedString("Quit HeliPort"),
                                            NSLocalizedString("Visit OpenIntelWireless on GitHub")]
        )

        if alert.show() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/OpenIntelWireless")!)
            return
        }

        NSApp.terminate(nil)
#endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Exit")
        api_terminate()
    }

    private func scheduleAutoQuitIfNeeded() {
        guard UserDefaults.standard.bool(forKey: .DefaultsKey.autoQuitEnabled) else { return }
        let delay = UserDefaults.standard.double(forKey: .DefaultsKey.autoQuitDelay)
        let seconds = delay > 0 ? delay : 60.0
        print("Auto-quit scheduled in \(Int(seconds)) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            print("Auto-quit triggered")
            NSApp.terminate(nil)
        }
    }
}
