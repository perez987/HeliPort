import Cocoa
import SwiftUI
import LocalAuthentication

class WiFiConfigWindow: NSWindow {

    private var windowState: WindowState
    private var networkInfo: NetworkInfo?
    private var getAuthInfoCallback: ((_ auth: NetworkAuth, _ savePassword: Bool) -> Void)?
    private var errorState: ErrorState?

    convenience init(windowState: WindowState = .joinWiFi,
                     networkInfo: NetworkInfo? = nil,
                     error: ErrorState? = nil,
                     getAuthInfoCallback: ((_ auth: NetworkAuth, _ savePassword: Bool) -> Void)? = nil) {
        self.init(contentRect: NSRect(x: 0, y: 0, width: 450, height: 320),
                  styleMask: [.titled, .fullSizeContentView],
                  backing: .buffered,
                  defer: false,
                  windowState: windowState,
                  networkInfo: networkInfo,
                  error: error,
                  getAuthInfoCallback: getAuthInfoCallback)
    }

    init(contentRect: NSRect,
         styleMask style: NSWindow.StyleMask,
         backing backingStoreType: NSWindow.BackingStoreType,
         defer flag: Bool,
         windowState: WindowState,
         networkInfo: NetworkInfo?,
         error: ErrorState?,
         getAuthInfoCallback: ((_ auth: NetworkAuth, _ savePassword: Bool) -> Void)? = nil) {

        self.windowState = windowState
        self.networkInfo = networkInfo
        self.getAuthInfoCallback = getAuthInfoCallback
        self.errorState = error

        super.init(contentRect: contentRect,
                   styleMask: style,
                   backing: backingStoreType,
                   defer: flag)

        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.center()

        let rootView = ModernWiFiConfigView(
            ssid: networkInfo?.ssid ?? "Unknown Network",
            onJoin: { password, save in
                self.handleJoin(password: password, save: save)
            },
            onCancel: {
                self.close()
            }
        )

        self.contentView = NSHostingView(rootView: rootView)

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func handleJoin(password: String, save: Bool) {
        if let network = networkInfo {
            network.auth.password = password
            getAuthInfoCallback?(network.auth, save)
        } else {
            // Manual join logic
            let network = NetworkInfo(ssid: networkInfo?.ssid ?? "")
            network.auth.password = password
            network.auth.security = ITL80211_SECURITY_WPA2_PERSONAL // Default for modern UI manual join
            NetworkManager.connect(networkInfo: network, saveNetwork: save)
        }
        self.close()
    }

    func show() {
        makeKeyAndOrderFront(self)
    }

    override func close() {
        if let sheet = sheetParent {
            sheet.endSheet(self, returnCode: .cancel)
        } else {
            super.close()
        }
    }
}

enum WindowState {
    case joinWiFi
    case connectWiFi
    case viewCredentialsWiFi
}

enum ErrorState: String {
    case timeout = "Connection timeout."
    case failed = "Connection failed."
    case cannotConnect = "Cannot connect."
    case incorrectPassword = "Incorrect password."
    var localizedString: String {
        return NSLocalizedString(self.rawValue)
    }
}
