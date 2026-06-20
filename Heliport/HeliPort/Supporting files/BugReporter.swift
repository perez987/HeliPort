//
//  BugReporter.swift
//  HeliPort
//
//  Created by Erik Bautista on 7/26/20.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa
import IOKit

class BugReporter {
    private static let openPanel: NSOpenPanel = {
        let openPanel = NSOpenPanel()

        openPanel.title = NSLocalizedString("Choose a folder to output the bug report")
        openPanel.message = NSLocalizedString("The bug report will be generated in the seleted folder")
        openPanel.showsResizeIndicator = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true

        NSApplication.shared.activate(ignoringOtherApps: true)

        return openPanel
    }()

    private class func generateHeliPortLog() -> String {
        """
        HeliPort now writes runtime messages directly to the console using print statements.
        System log collection for HeliPort is no longer available in generated bug reports.
        """
    }

    private class func generateItlwmLog() -> String {
        var response: String?

        if KextInfo("as.lvs1974.DebugEnhancer").kextDidLoad() {
            // msgbuf size is sufficient, collect dmesg logs
            response = NSAppleScript(source:
                // swiftlint:disable line_length
                """
                do shell script \"sudo dmesg | grep -E \\"itlwm|Airport|IO80211|EAPOL\\"\" with administrator privileges
                """)!.executeAndReturnError(nil).stringValue
            // swiftlint:enable line_length
        } else {
            response = .msgbufInsufficient
        }

        return response ?? .scriptFailed
    }

    class func generateBugReport() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown"
        let appBuildVer = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown"

        let appLog = generateHeliPortLog()

        // MARK: itlwm log

        var driverInfo = ioctl_driver_info()
        _ = ioctl_get(Int32(IOCTL_80211_DRIVER_INFO.rawValue), &driverInfo, MemoryLayout<ioctl_driver_info>.size)
        var itlwmVer = String(cCharArray: driverInfo.driver_version)
        var itlwmFwVer = String(cCharArray: driverInfo.fw_version)
        if itlwmVer.isEmpty { itlwmVer = "Unknown" }
        if itlwmFwVer.isEmpty { itlwmFwVer = "Unknown" }

        let itlwmLog = generateItlwmLog()

        if itlwmLog == .msgbufInsufficient || itlwmLog == .scriptFailed {
            DispatchQueue.main.async {
                let alert = CriticalAlert(
                    message: NSLocalizedString("Error occurred while generating bug report."),
                    informativeText: itlwmLog == .msgbufInsufficient ?
                        NSLocalizedString("Make sure you have installed `DebugEnhancer.kext`" +
                            " before collecting logs for itlwm.") :
                        NSLocalizedString("Could not read logs for `itlwm`." +
                            " Make sure you allow `HeliPort` to read logs when prompted."),
                    options: [NSLocalizedString("Dismiss"), NSLocalizedString("Open Documentation")],
                    helpAnchor: .dmesgHelpURL,
                    errorText: itlwmLog
                )

                if alert.show() == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(URL(string: .dmesgHelpURL)!)
                }
            }
            return
        }

        // MARK: Get itlwm name if loaded (itlwm or itlwmx)

        let kextstatCommand = ["-c", "kextstat"]
        let itlwmLoaded = Commands.execute(executablePath: .shell, args: kextstatCommand)
        var itlwmName: String?
        if let regex = try? NSRegularExpression(pattern: "\\b(itlwm\\w*)\\b", options: []), itlwmLoaded.0 != nil {
            let firstMatch = regex.firstMatch(in: itlwmLoaded.0!,
                                              options: [],
                                              range: NSRange(location: 0, length: itlwmLoaded.0!.count))
            if let range = firstMatch?.range(at: 1) {
                if let swiftRange = Range(range, in: itlwmLoaded.0!) {
                    itlwmName = String(itlwmLoaded.0![swiftRange])
                }
            }
        }

        // MARK: Output String

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        let dateRan = "Time ran: \(formatter.string(from: date))"
        let osVersion = ProcessInfo().operatingSystemVersionString
        let appOutput = """
        \(appLog)

        \(dateRan)
        HeliPort Version: \(appVersion) (Build \(appBuildVer))

        macOS \(osVersion)
        """
        let itlwmOutput = """
        \(itlwmLog)

        \(dateRan)
        \(itlwmName != nil ? "\(itlwmName!) loaded version: \(itlwmVer) (Firmware: \(itlwmFwVer))" :
            "Kext not loaded")

        macOS \(osVersion)
        """

        DispatchQueue.main.async {
            openPanel.begin { result in
                var folderUrl: URL?
                if result == NSApplication.ModalResponse.OK {
                    folderUrl = openPanel.url
                }

                // Back to background
                DispatchQueue.global().async {
                    guard folderUrl != nil else {
                        print("Could not get path to store bug report.")
                        DispatchQueue.main.async {
                            let alert = CriticalAlert(
                                message: NSLocalizedString("Could not get path to generate bug report."),
                                options: ["Dismiss"]
                            )
                            alert.show()
                        }
                        return
                    }

                    let reportDirName = "bugreport_\(UInt16.random(in: UInt16.min ... UInt16.max))"
                    let reportDirUrl = folderUrl!.appendingPathComponent(reportDirName, isDirectory: true)

                    // MARK: Write to files

                    do {
                        try FileManager.default.createDirectory(at: reportDirUrl,
                                                                withIntermediateDirectories: true,
                                                                attributes: nil)
                        let heliPortFile = reportDirUrl.appendingPathComponent("HeliPort_logs.log")
                        let itlwmFile = reportDirUrl.appendingPathComponent("\(itlwmName ?? "itlwm")_logs.log")
                        try appOutput.write(to: heliPortFile, atomically: true, encoding: .utf8)
                        try itlwmOutput.write(to: itlwmFile, atomically: true, encoding: .utf8)
                    } catch {
                        print("\(error)")
                        return
                    }

                    // MARK: Zip file

                    let zipName = reportDirName + ".zip"
                    let zipCommand = ["-c", "cd \(folderUrl!.path) && " +
                        "zip -r -X -m \(zipName) \(reportDirName)"]
                    let outputExitCode = Commands.execute(executablePath: .shell, args: zipCommand).1
                    guard outputExitCode == 0 else {
                        print("Could not create zip file: Exit code: \(outputExitCode)")
                        DispatchQueue.main.async {
                            let alert = CriticalAlert(
                                message: NSLocalizedString("Could not create zip file for generated logs."),
                                options: [NSLocalizedString("Dismiss")]
                            )
                            alert.show()
                        }
                        return
                    }

                    // MARK: Select zip file

                    NSWorkspace.shared.selectFile("\(folderUrl!.path)/\(zipName)",
                                                  inFileViewerRootedAtPath: folderUrl!.path)
                }
            }
        }
    }
}

private extension String {
    // MARK: ITLWM Generation errors

    static let msgbufInsufficient = "MSGBUF-INSUFFICIENT"
    static let scriptFailed = "SCRIPT-FAILED"

    // MARK: DOC URL

    static let dmesgHelpURL = "https://docs.oiw.workers.dev/itlwm/Troubleshooting.html#runtime-logs"
}
