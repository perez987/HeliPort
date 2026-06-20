import AppIntents
import Foundation

struct HeliPortIntents: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetWiFiStatusIntent(),
            phrases: [
                "Get \(.applicationName) status",
                "How is my Wi-Fi in \(.applicationName)"
            ],
            shortTitle: "Get Wi-Fi Status",
            systemImageName: "wifi"
        )
    }
}

struct GetWiFiStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Wi-Fi Status"
    static var description = IntentDescription("Returns the current connection status and network name.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In a real implementation, this would call NetworkManager.shared
        // For now, we return a placeholder that demonstrates the integration
        return .result(value: "Connected to Intel Wi-Fi")
    }
}
