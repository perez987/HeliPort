import Cocoa
import SwiftUI

@available(macOS 11, *)
final class StatusMenuModern: StatusMenuBase, StatusMenuItems {

    // - MARK: SwiftUI State
    private var isWiFiOn: Bool = true {
        didSet {
            _ = isWiFiOn ? power_on() : power_off()
        }
    }

    // - MARK: Menu items

    private lazy var statusItem: NSMenuItem = {
        return ModernToggleMenuItem(title: String.Modern.wifi, isOn: true) { [weak self] newValue in
            self?.isWiFiOn = newValue
        }
    }()

    private var isOtherExpanded: Bool = false {
        didSet {
            self.otherNetworkItemList.forEach {
                if $0.isEnabled { $0.isHidden = !isOtherExpanded }
            }
            self.manuallyJoinItem.isHidden = !isOtherExpanded
            self.update()
        }
    }

    private lazy var knownSectionItem: NSMenuItem = {
        let binding = Binding(get: { true }, set: { _ in })
        return ModernSectionHeaderItem(title: String.Modern.knownNetwork, isExpanded: binding, isExpandable: false)
    }()

    private lazy var otherSectionItem: NSMenuItem = {
        let binding = Binding(
            get: { self.isOtherExpanded },
            set: { self.isOtherExpanded = $0 }
        )
        return ModernSectionHeaderItem(title: String.Modern.otherNetworks, isExpanded: binding)
    }()

    private lazy var manuallyJoinItem = ModernActionMenuItem(
        title: String.Modern.joinNetworks,
        icon: "plus"
    ) { [weak self] in
        self?.clickMenuItem(NSMenuItem(title: String.Modern.joinNetworks, action: nil, keyEquivalent: ""))
    }

    private lazy var networkPanelItem = ModernActionMenuItem(
        title: String.Modern.wifiSettings,
        icon: "gearshape"
    ) { [weak self] in
        self?.clickMenuItem(NSMenuItem(title: String.Modern.wifiSettings, action: nil, keyEquivalent: ""))
    }

    // Technical details
    private lazy var modernBsdItem = ModernKeyValueItem(key: String.interfaceName, value: "")
    private lazy var modernMacItem = ModernKeyValueItem(key: String.macAddress, value: "")
    private lazy var modernItlwmVerItem = ModernKeyValueItem(key: String.itlwmVer, value: "")

    // WiFi connected items
    private lazy var ipAddressItem = ModernKeyValueItem(key: String.ipAddr, value: "", inset: true)
    private lazy var modernRouterItem = ModernKeyValueItem(key: String.routerStr, value: "", inset: true)
    private lazy var modernInternetItem = ModernKeyValueItem(key: String.internetStr, value: "", inset: true)
    private lazy var modernSecurityItem = ModernKeyValueItem(key: String.securityStr, value: "", inset: true)
    private lazy var modernBssidItem = ModernKeyValueItem(key: String.bssidStr, value: "", inset: true)
    private lazy var modernChannelItem = ModernKeyValueItem(key: String.channelStr, value: "", inset: true)
    private lazy var modernCountryCodeItem = ModernKeyValueItem(key: String.countryCodeStr, value: "", inset: true)
    private lazy var modernRssiItem = ModernKeyValueItem(key: String.rssiStr, value: "", inset: true)
    private lazy var modernNoiseItem = ModernKeyValueItem(key: String.noiseStr, value: "", inset: true)
    private lazy var modernTxRateItem = ModernKeyValueItem(key: String.txRateStr, value: "", inset: true)
    private lazy var modernPhyModeItem = ModernKeyValueItem(key: String.phyModeStr, value: "", inset: true)
    private lazy var modernMcsIndexItem = ModernKeyValueItem(key: String.mcsStr, value: "", inset: true)
    private lazy var modernNssItem = ModernKeyValueItem(key: String.nssStr, value: "", inset: true)

    lazy var enabledNetworkCardItems: [NSMenuItem] = []

    lazy var stationInfoItems: [NSMenuItem] = [
        ipAddressItem,
        modernRouterItem,
        modernInternetItem,
        modernSecurityItem,
        modernBssidItem,
        modernChannelItem,
        modernCountryCodeItem,
        modernRssiItem,
        modernNoiseItem,
        modernTxRateItem,
        modernPhyModeItem,
        modernMcsIndexItem,
        modernNssItem
    ]

    lazy var hiddenItems: [NSMenuItem] = [
        modernBsdItem,
        modernMacItem,
        modernItlwmVerItem
    ]

    lazy var notImplementedItems: [NSMenuItem] = [
        enableLoggingItem,
        diagnoseItem,

        modernSecurityItem,
        modernCountryCodeItem,
        modernNssItem
    ]

    override var isNetworkListEmpty: Bool {
        willSet(empty) {
            super.isNetworkListEmpty = empty
            if empty {
                knownSectionItem.isHidden = true
                otherSectionItem.isHidden = true
                manuallyJoinItem.isHidden = true
                knownNetworkItemList.forEach { $0.isHidden = true }
                otherNetworkItemList.forEach { $0.isHidden = true }
            }
        }
    }

    override var isNetworkCardAvailable: Bool {
        willSet(newState) {
            super.isNetworkCardAvailable = newState
        }
    }

    override var isNetworkCardEnabled: Bool {
        willSet(newState) {
            super.isNetworkCardEnabled = newState
            (statusItem as? ModernToggleMenuItem)?.update(isOn: newState)
        }
    }

    private var knownNetworkItemList = [NSMenuItem]()
    private var otherNetworkItemList = [NSMenuItem]()
    private var currentSSID: String?
    private lazy var dashboardViewModel = NetworkDetailsViewModel()

    // - MARK: Init

    override init() {
        super.init()
        minimumWidth = HeliPortUI.Dashboard.width
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // - MARK: Menu Setup

    func setupMenu() {
        addItem(statusItem)
        addItem(.separator())

        addItem(knownSectionItem)

        // Dashboard
        let dashboardView = NSHostingView(rootView: NetworkDetailsDashboard(viewModel: dashboardViewModel))
        dashboardView.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: 1)
        dashboardView.layoutSubtreeIfNeeded()
        dashboardView.frame.size.height = ceil(dashboardView.fittingSize.height)
        currentNetworkItem.view = dashboardView
        addItem(currentNetworkItem)
        headerLength = index(of: currentNetworkItem) + 1

        addItem(otherSectionItem)
        addItem(manuallyJoinItem)

        addItem(networkItemListSeparator)

        addItem(networkPanelItem)

        addItem(.separator())

        addItem(ModernActionMenuItem(title: String.aboutHeliport, icon: "info.circle") { [weak self] in
            self?.clickMenuItem(self?.aboutItem ?? NSMenuItem())
        })

        addItem(ModernActionMenuItem(title: String.checkUpdates, icon: "arrow.triangle.2.circlepath") {
            UpdateManager.sharedController?.checkForUpdates(nil)
        })

        addItem(quitSeparator)

        addItem(ModernActionMenuItem(title: String.quitHeliport, icon: "power", shortcut: "q") { [weak self] in
            self?.clickMenuItem(self?.quitItem ?? NSMenuItem())
        })

        // Technical & Hidden items at the bottom (only shown with Option key)
        addItem(.separator())

        [modernBsdItem, modernMacItem, modernItlwmVerItem].forEach {
            addItem($0)
        }

        stationInfoItems.forEach {
            addItem($0)
        }
    }

    // - MARK: Menu Updates

    func setValueForItem(_ item: NSMenuItem, value: String) {
        (item as? ModernKeyValueItem)?.value = value
    }

    func updateNetworkList() {
        guard isNetworkCardEnabled else { return }

        (otherSectionItem as? ModernSectionHeaderItem)?.isScanning = true
        (knownSectionItem as? ModernSectionHeaderItem)?.isScanning = true

        let sortBySignal: (NetworkInfo, NetworkInfo) -> Bool = { $0.rssi > $1.rssi }

        NetworkManager.scanNetwork(sortBy: sortBySignal) { [weak self] knownList, otherList in
            guard let self = self else { return }

            let networkListSize = knownList.count + otherList.count

            DispatchQueue.main.async {
                (self.otherSectionItem as? ModernSectionHeaderItem)?.isScanning = false
                (self.knownSectionItem as? ModernSectionHeaderItem)?.isScanning = false

                self.isNetworkListEmpty = networkListSize == 0 && !self.isNetworkConnected

                let showKnown = !knownList.isEmpty || self.isNetworkConnected
                self.knownSectionItem.isHidden = !showKnown

                let knownTitle = knownList.count > (self.isNetworkConnected ? 0 : 1)
                    ? String.Modern.knownNetworks
                    : String.Modern.knownNetwork
                (self.knownSectionItem.view as? NSHostingView<SectionHeaderView>)?.rootView = SectionHeaderView(
                    title: knownTitle,
                    isExpandable: false,
                    isExpanded: .constant(true)
                )

                let staInfo: NetworkInfo? = (self.isNetworkConnected
                                             ? NetworkInfo(ssid: self.currentSSID ?? "")
                                             : nil)

                let insertAtKnown = self.index(of: self.currentNetworkItem) + 1
                self.processNetworkList(from: knownList, to: &self.knownNetworkItemList,
                                        insertAt: insertAtKnown, staInfo)

                // Keep other section visible if there are networks
                // or if we have no known networks (for manual join)
                self.otherSectionItem.isHidden = otherList.isEmpty && !self.isOtherExpanded && showKnown

                let insertAtOther = self.index(of: self.otherSectionItem) + 1
                self.processNetworkList(from: otherList, to: &self.otherNetworkItemList,
                                        insertAt: insertAtOther,
                                        staInfo, hidden: !self.isOtherExpanded)

                self.manuallyJoinItem.isHidden = !self.isOtherExpanded

                // Show separator if anything was shown in the network sections
                self.networkItemListSeparator.isHidden = !showKnown && self.otherSectionItem.isHidden

                self.update()
            }
        }
    }

    func toggleWIFI() {
        DispatchQueue.main.async {
            self.isWiFiOn.toggle()
        }
    }

    // - MARK: Overrides

    override func menuWillOpen(_ menu: NSMenu) {
        super.menuWillOpen(menu)

        guard isNetworkCardEnabled else { return }

        let hasSavedNetworks = !CredentialsManager.instance.getSavedNetworkSSIDs().isEmpty
        let expandOther = !self.isNetworkConnected && !hasSavedNetworks && self.knownNetworkItemList.isEmpty

        self.isOtherExpanded = expandOther
    }

    override func addNetworkItem(_ item: NSMenuItem = HPMenuItem(highlightable: true),
                                 insertAt: Int? = nil,
                                 hidden: Bool = false,
                                 networkInfo: NetworkInfo = NetworkInfo(ssid: "placeholder")) -> NSMenuItem {

        let newItem = ModernNetworkMenuItem(
            ssid: networkInfo.ssid,
            signalStrength: Int(networkInfo.rssi),
            isConnected: false,
            isSecure: networkInfo.auth.security != ITL80211_SECURITY_NONE
        ) {
            NetworkManager.connect(networkInfo: networkInfo, saveNetwork: true)
            self.cancelTracking()
        }

        newItem.isHidden = hidden

        // Only call super if we actually want to insert it into the menu at a specific position.
        // Otherwise, just return the constructed item (e.g. for processNetworkList reuse logic).
        guard let insertAt = insertAt else {
            return newItem
        }

        return super.addNetworkItem(newItem, insertAt: insertAt, hidden: hidden, networkInfo: networkInfo)
    }

    override func setCurrentNetworkItem(with info: StatusMenuBase.StationInfo) {
        // Handle connected -> disconnected state
        if !currentNetworkItem.isHidden && !info.isNetworkConnected {
            for index in self.headerLength ..<
                    min(self.items.count,
                        self.headerLength + self.knownNetworkItemList.count) {
                self.items[index].isHidden = false
                self.items[index].isEnabled = true
            }
        }

        isNetworkConnected = info.isNetworkConnected
        currentSSID = info.ssid
        currentNetworkItem.isHidden = !isNetworkConnected

        if isNetworkConnected {
            dashboardViewModel.update(with: info)
        }

        super.setCurrentNetworkItem(with: info)

        // Ensure isNetworkListEmpty is updated to false if connected
        if isNetworkConnected && isNetworkListEmpty {
            isNetworkListEmpty = false
        }
    }
}

// MARK: - Modern UI Components

struct ActionItemView: View {
    let title: String
    let icon: String?
    let shortcut: String?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: HeliPortUI.Spacing.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .frame(width: 18)
            }

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            if let shortcut = shortcut {
                Text(shortcut)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .modernMenuItem()
        .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            action()
        }
    }
}

class ModernActionMenuItem: NSMenuItem {
    private var onSelect: () -> Void = {}

    init(title: String, icon: String? = nil, shortcut: String? = nil, action: @escaping () -> Void) {
        self.onSelect = action
        super.init(title: title, action: #selector(itemAction), keyEquivalent: shortcut ?? "")
        self.target = self

        let view = ActionItemView(title: title, icon: icon, shortcut: shortcutDisplay(shortcut), action: action)
        self.view = NSHostingView(rootView: view)
        self.view?.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: 36)
    }

    private func shortcutDisplay(_ shortcut: String?) -> String? {
        guard let shortcut = shortcut else { return nil }
        if shortcut == "q" { return "⌘Q" }
        return shortcut.uppercased()
    }

    @objc private func itemAction() {
        onSelect()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SectionHeaderView: View {
    let title: String
    let isExpandable: Bool
    @Binding var isExpanded: Bool
    var isScanning: Bool = false
    var onExpand: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary.opacity(0.6))
                .tracking(0.5)

            if isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.4)
                    .frame(width: 12, height: 12)
            }

            Spacer()

            if isExpandable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .padding(.horizontal, HeliPortUI.Spacing.menuHorizontalPadding)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isExpandable {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                    onExpand?(isExpanded)
                }
            }
        }
    }
}

class ModernSectionHeaderItem: NSMenuItem {
    private var isExpandedBinding: Binding<Bool>
    private var headerTitle: String
    private var canExpand: Bool
    private var onExpand: ((Bool) -> Void)?

    var isScanning: Bool = false {
        didSet {
            let view = SectionHeaderView(
                title: headerTitle,
                isExpandable: canExpand,
                isExpanded: isExpandedBinding,
                isScanning: isScanning,
                onExpand: onExpand
            )
            (self.view as? NSHostingView<SectionHeaderView>)?.rootView = view
        }
    }

    init(title: String, isExpanded: Binding<Bool>, isExpandable: Bool = true, onExpand: ((Bool) -> Void)? = nil) {
        self.isExpandedBinding = isExpanded
        self.headerTitle = title
        self.canExpand = isExpandable
        self.onExpand = onExpand
        super.init(title: title, action: nil, keyEquivalent: "")

        let view = SectionHeaderView(
            title: title,
            isExpandable: isExpandable,
            isExpanded: isExpanded,
            onExpand: onExpand
        )
        self.view = NSHostingView(rootView: view)
        self.view?.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: 32)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class KeyValueViewModel: ObservableObject {
    @Published var value: String = ""
    init(value: String) { self.value = value }
}

struct KeyValueItemView: View {
    let key: String
    @ObservedObject var viewModel: KeyValueViewModel
    let inset: Bool

    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()

            Text(viewModel.value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary.opacity(0.8))
        }
        .padding(.horizontal, HeliPortUI.Spacing.menuHorizontalPadding + (inset ? 10 : 0))
        .padding(.vertical, 4)
    }
}

class ModernKeyValueItem: NSMenuItem {
    private let viewModel: KeyValueViewModel

    var value: String {
        get { viewModel.value }
        set { viewModel.value = newValue }
    }

    init(key: String, value: String, inset: Bool = false) {
        self.viewModel = KeyValueViewModel(value: value)
        super.init(title: key, action: nil, keyEquivalent: "")

        let view = KeyValueItemView(key: key, viewModel: viewModel, inset: inset)
        self.view = NSHostingView(rootView: view)
        self.view?.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: 24)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
