//
//  SimulatedDriver.swift
//  HeliPort
//
//  Copyright © 2026 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation

enum SimulationMode {
    static let defaultsKey = "simulationModeEnabled"
    static let interfaceDefaultsKey = "simulationNetworkInterface"

    static var isEnabled: Bool {
        isForcedByLaunchArgument || isStoredEnabled
    }

    static var isForcedByLaunchArgument: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate")
    }

    static var isStoredEnabled: Bool {
        UserDefaults.standard.bool(forKey: defaultsKey)
    }

    static var networkInterface: String {
        let value = UserDefaults.standard.string(forKey: interfaceDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "en0" : value
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: defaultsKey)
    }

    static func setNetworkInterface(_ interface: String) {
        UserDefaults.standard.set(interface, forKey: interfaceDefaultsKey)
    }
}

enum Driver {
    static var isSimulated: Bool {
        SimulationMode.isEnabled
    }

    static func driverInfo() -> ioctl_driver_info? {
        if isSimulated { return SimulatedWiFi.driverInfo() }

        var info = ioctl_driver_info()
        guard ioctl_get(Int32(IOCTL_80211_DRIVER_INFO.rawValue), &info,
                        MemoryLayout<ioctl_driver_info>.size) == KERN_SUCCESS
        else {
            return nil
        }
        return info
    }

    static func platformInfo() -> platform_info_t? {
        if isSimulated { return SimulatedWiFi.platformInfo() }

        var info = platform_info_t()
        guard get_platform_info(&info) else { return nil }
        return info
    }

    static func powerState() -> Bool? {
        if isSimulated { return SimulatedWiFi.powerState() }

        var enabled = false
        guard get_power_state(&enabled) else { return nil }
        return enabled
    }

    static func state() -> itl_80211_state? {
        if isSimulated { return SimulatedWiFi.state() }

        var rawState: UInt32 = 0
        guard get_80211_state(&rawState) else { return nil }
        return itl_80211_state(rawValue: rawState)
    }

    static func stationInfo() -> station_info_t? {
        if isSimulated { return SimulatedWiFi.stationInfo() }

        var info = station_info_t()
        guard get_station_info(&info) == KERN_SUCCESS else { return nil }
        return info
    }

    static func networkList() -> Set<NetworkInfo> {
        if isSimulated { return SimulatedWiFi.networkList() }

        var list = network_info_list_t()
        get_network_list(&list)

        var result = Set<NetworkInfo>()
        let networks = Mirror(reflecting: list.networks).children.map { $0.value }.prefix(Int(list.count))
        for element in networks {
            guard let network = element as? ioctl_network_info else { continue }
            let ssid = String(ssid: network.ssid)
            guard !ssid.isEmpty else { continue }

            let networkInfo = NetworkInfo(ssid: ssid, rssi: Int(network.rssi))
            networkInfo.auth.security = NetworkManager.getSecurityType(network)
            result.insert(networkInfo)
        }
        return result
    }

    static func setPower(_ enabled: Bool) -> Bool {
        if isSimulated { return SimulatedWiFi.setPower(enabled) }
        return (enabled ? power_on() : power_off()) == KERN_SUCCESS
    }

    static func connect(ssid: String, password: String) -> Bool {
        if isSimulated { return SimulatedWiFi.connect(ssid: ssid, password: password) }
        return connect_network(ssid, password)
    }

    static func disassociate(ssid: String) {
        if isSimulated {
            SimulatedWiFi.disassociate(ssid: ssid)
        } else {
            dis_associate_ssid(ssid)
        }
    }

    static func terminate() {
        if !isSimulated {
            api_terminate()
        }
    }
}

private enum SimulatedWiFi {
    private static let lock = NSLock()
    private static var powered = true
    private static var currentState: itl_80211_state = ITL80211_S_RUN
    private static var connectedSSID: String? = "Simul Net"
    private static var signalStrength: Int16 = -52

    private static let networks: [(ssid: String, rssi: Int, security: itl80211_security)] = [
        ("Simul Net", -52, ITL80211_SECURITY_WPA2_PERSONAL),
        ("Home Network", -61, ITL80211_SECURITY_WPA2_PERSONAL),
        ("Cafe Guest", -68, ITL80211_SECURITY_NONE),
        ("Neighbour 5G", -74, ITL80211_SECURITY_WPA2_PERSONAL),
        ("Office", -83, ITL80211_SECURITY_WPA2_PERSONAL),
    ]

    static func driverInfo() -> ioctl_driver_info {
        var info = ioctl_driver_info()
        info.version = UInt32(IOCTL_VERSION)
        copyString("simulated", into: &info.fw_version)
        copyString("1.0.0-sim", into: &info.driver_version)
        copyString(SimulationMode.networkInterface, into: &info.bsd_name)
        return info
    }

    static func platformInfo() -> platform_info_t {
        var info = platform_info_t()
        copyString(SimulationMode.networkInterface, into: &info.device_info_str)
        copyString("Simulated Wi-Fi", into: &info.driver_info_str)
        return info
    }

    static func powerState() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return powered
    }

    static func setPower(_ enabled: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        powered = enabled
        currentState = enabled
            ? (connectedSSID == nil ? ITL80211_S_SCAN : ITL80211_S_RUN)
            : ITL80211_S_INIT
        return true
    }

    static func state() -> itl_80211_state {
        lock.lock()
        defer { lock.unlock() }
        return currentState
    }

    static func stationInfo() -> station_info_t? {
        lock.lock()
        defer { lock.unlock() }
        guard powered, currentState == ITL80211_S_RUN, let ssid = connectedSSID else { return nil }

        var info = station_info_t()
        info.version = UInt32(IOCTL_VERSION)
        info.op_mode = ITL80211_MODE_11AX
        info.max_mcs = 11
        info.cur_mcs = 9
        info.channel = 44
        info.band_width = 80
        info.rssi = signalStrength
        info.noise = -92
        info.rate = 1200
        copyString(ssid, into: &info.ssid)
        copyBytes([0, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E], into: &info.bssid)
        return info
    }

    static func networkList() -> Set<NetworkInfo> {
        lock.lock()
        let connected = connectedSSID
        let isPowered = powered
        lock.unlock()
        guard isPowered else { return [] }

        return Set(networks.compactMap { network in
            guard network.ssid != connected else { return nil }
            let info = NetworkInfo(ssid: network.ssid, rssi: network.rssi)
            info.auth.security = network.security
            return info
        })
    }

    static func connect(ssid: String, password: String) -> Bool {
        Thread.sleep(forTimeInterval: 1)
        lock.lock()
        defer { lock.unlock() }
        guard powered else { return false }

        let security = networks.first(where: { $0.ssid == ssid })?.security ?? ITL80211_SECURITY_WPA2_PERSONAL
        guard security == ITL80211_SECURITY_NONE || !password.isEmpty else { return false }
        connectedSSID = ssid
        currentState = ITL80211_S_RUN
        signalStrength = Int16(networks.first(where: { $0.ssid == ssid })?.rssi ?? -60)
        return true
    }

    static func disassociate(ssid: String) {
        lock.lock()
        defer { lock.unlock() }
        guard connectedSSID == ssid else { return }
        connectedSSID = nil
        currentState = ITL80211_S_SCAN
    }

    private static func copyString<T>(_ string: String, into field: inout T) {
        withUnsafeMutableBytes(of: &field) { raw in
            guard !raw.isEmpty else { return }
            raw.copyBytes(from: Array(string.utf8).prefix(raw.count - 1))
        }
    }

    private static func copyBytes<T>(_ bytes: [UInt8], into field: inout T) {
        withUnsafeMutableBytes(of: &field) { raw in
            guard !raw.isEmpty else { return }
            raw.copyBytes(from: bytes.prefix(raw.count))
        }
    }
}
