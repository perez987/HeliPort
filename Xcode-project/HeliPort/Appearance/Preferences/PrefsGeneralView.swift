//
//  PrefsGeneralView.swift
//  HeliPort
//
//  Created by Erik Bautista on 8/3/20.
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

class PrefsGeneralView: NSView {
    let updatesLabel: NSTextField = {
        let view = NSTextField(labelWithString: .startup)
        view.alignment = .right
        return view
    }()

    lazy var autoUpdateCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .autoCheckUpdate,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .autoUpdateId
        checkbox.state = UpdateManager.sharedUpdater?.automaticallyChecksForUpdates ?? false ? .on : .off
        return checkbox
    }()

    lazy var autoDownloadCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .autoDownload,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .autoDownloadId
        checkbox.state = UpdateManager.sharedUpdater?.automaticallyDownloadsUpdates ?? false ? .on : .off
        return checkbox
    }()

    lazy var bitrateCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .showBitrate,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .bitrateId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.showBitrateInMenuBar) ? .on : .off
        return checkbox
    }()

    lazy var signalPercentageCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .showSignalPercentage,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .signalPercentageId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.showSignalAsPercentage) ? .on : .off
        return checkbox
    }()

    lazy var launchAtLoginCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .launchLogin,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .launchAtLoginId
        checkbox.state = LoginItemManager.isEnabled() ? .on : .off
        return checkbox
    }()

    lazy var autoQuitCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .autoQuit,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .autoQuitId
        checkbox.state = UserDefaults.standard.bool(forKey: .DefaultsKey.autoQuitEnabled) ? .on : .off
        return checkbox
    }()

    lazy var simulatedDriverCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: .simulatedDriver,
                                target: self,
                                action: #selector(checkboxChanged(_:)))
        checkbox.identifier = .simulationModeId
        checkbox.state = SimulationMode.isEnabled ? .on : .off
        checkbox.isEnabled = !SimulationMode.isForcedByLaunchArgument
        return checkbox
    }()

    lazy var networkInterfaceField: NSTextField = {
        let field = NSTextField(string: SimulationMode.networkInterface)
        field.target = self
        field.action = #selector(networkInterfaceChanged(_:))
        field.isEnabled = SimulationMode.isEnabled
        return field
    }()

    lazy var autoQuitDelayStepper: NSStepper = {
        let stepper = NSStepper()
        stepper.minValue = 30
        stepper.maxValue = 600
        stepper.increment = 30
        let stored = UserDefaults.standard.double(forKey: .DefaultsKey.autoQuitDelay)
        stepper.doubleValue = stored > 0 ? stored : 60
        stepper.target = self
        stepper.action = #selector(autoQuitDelayChanged(_:))
        stepper.isEnabled = UserDefaults.standard.bool(forKey: .DefaultsKey.autoQuitEnabled)
        return stepper
    }()

    lazy var autoQuitDelayLabel: NSTextField = {
        let stored = UserDefaults.standard.double(forKey: .DefaultsKey.autoQuitDelay)
        let seconds = stored > 0 ? Int(stored) : 60
        return NSTextField(labelWithString: String(format: NSLocalizedString("after %d s"), seconds))
    }()

    let gridView: NSGridView = {
        let view = NSGridView()
        view.setContentHuggingPriority(.init(rawValue: 600), for: .horizontal)
        return view
    }()

    convenience init() {
        self.init(frame: NSRect.zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        gridView.addRow(with: [updatesLabel])
        gridView.addColumn(with: [autoUpdateCheckbox, autoDownloadCheckbox])

        let extrasLabel = NSTextField(labelWithString: "Extras:")
        extrasLabel.alignment = .right
        gridView.addRow(with: [extrasLabel, bitrateCheckbox])
        gridView.addRow(with: [NSView(), signalPercentageCheckbox])
        gridView.addRow(with: [NSView(), launchAtLoginCheckbox])
        let autoQuitRow = NSStackView(views: [autoQuitCheckbox, autoQuitDelayStepper, autoQuitDelayLabel])
        autoQuitRow.orientation = .horizontal
        autoQuitRow.spacing = 4
        gridView.addRow(with: [NSView(), autoQuitRow])
        let testingLabel = NSTextField(labelWithString: .simulationSettings)
        testingLabel.alignment = .right
        gridView.addRow(with: [testingLabel, simulatedDriverCheckbox])
        gridView.addRow(with: [NSView(), NSStackView(views: [
            NSTextField(labelWithString: .networkInterface),
            networkInterfaceField
        ])])

        addSubview(gridView)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let inset: CGFloat = 20
        gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset).isActive = true
        gridView.topAnchor.constraint(equalTo: topAnchor, constant: inset).isActive = true
        gridView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset).isActive = true
        gridView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset).isActive = true
    }
}

extension PrefsGeneralView {
    @objc private func checkboxChanged(_ sender: NSButton) {
        guard let identifier = sender.identifier else { return }
        print("State changed for \(identifier)")

        switch identifier {
        case .autoUpdateId:
            UpdateManager.sharedUpdater?.automaticallyChecksForUpdates = sender.state == .on
        case .autoDownloadId:
            UpdateManager.sharedUpdater?.automaticallyDownloadsUpdates = sender.state == .on
        case .bitrateId:
            UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.showBitrateInMenuBar)
        // Notify StatusBarIcon to update immediately if possible
        case .signalPercentageId:
            UserDefaults.standard.set(sender.state == .on, forKey: .DefaultsKey.showSignalAsPercentage)
        case .launchAtLoginId:
            LoginItemManager.setStatus(enabled: sender.state == .on)
        case .autoQuitId:
            let enabled = sender.state == .on
            UserDefaults.standard.set(enabled, forKey: .DefaultsKey.autoQuitEnabled)
            autoQuitDelayStepper.isEnabled = enabled
        case .simulationModeId:
            SimulationMode.setEnabled(sender.state == .on)
            networkInterfaceField.isEnabled = sender.state == .on
        default:
            break
        }
    }

    @objc private func networkInterfaceChanged(_ sender: NSTextField) {
        SimulationMode.setNetworkInterface(sender.stringValue)
    }

    @objc private func autoQuitDelayChanged(_ sender: NSStepper) {
        let seconds = Int(sender.doubleValue)
        UserDefaults.standard.set(sender.doubleValue, forKey: .DefaultsKey.autoQuitDelay)
        autoQuitDelayLabel.stringValue = String(format: NSLocalizedString("after %d s"), seconds)
        print("Auto-quit delay set to \(seconds)s")
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let autoUpdateId = NSUserInterfaceItemIdentifier(rawValue: "AutoUpdateCheckbox")
    static let autoDownloadId = NSUserInterfaceItemIdentifier(rawValue: "AutoDownloadCheckbox")
    static let bitrateId = NSUserInterfaceItemIdentifier(rawValue: "BitrateCheckbox")
    static let signalPercentageId = NSUserInterfaceItemIdentifier(rawValue: "SignalPercentageCheckbox")
    static let launchAtLoginId = NSUserInterfaceItemIdentifier(rawValue: "LaunchAtLoginCheckbox")
    static let autoQuitId = NSUserInterfaceItemIdentifier(rawValue: "AutoQuitCheckbox")
    static let simulationModeId = NSUserInterfaceItemIdentifier(rawValue: "SimulationModeCheckbox")
}

private extension String {
    static let startup = NSLocalizedString("Updates:")
    static let autoCheckUpdate = NSLocalizedString("Automatically check for updates.")
    static let autoDownload = NSLocalizedString("Automatically download new updates.")

    static let showBitrate = NSLocalizedString("Show live bitrate in menu bar")
    static let showSignalPercentage = NSLocalizedString("Show signal as percentage")
    static let autoQuit = NSLocalizedString("Quit Heliport automatically")
    static let simulationSettings = NSLocalizedString("Testing:")
    static let simulatedDriver = NSLocalizedString("Use simulated driver")
    static let networkInterface = NSLocalizedString("Host interface for IP details:")
}
