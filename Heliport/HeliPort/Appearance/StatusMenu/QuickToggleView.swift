import SwiftUI

class WifiToggleState: ObservableObject {
    @Published var isOn: Bool
    init(isOn: Bool) { self.isOn = isOn }
}

struct QuickToggleView: View {
    @ObservedObject var state: WifiToggleState
    let title: String
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { state.isOn },
                set: { newValue in
                    state.isOn = newValue
                    onToggle(newValue)
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .labelsHidden()
        }
        .modernMenuItem()
    }
}

class ModernToggleMenuItem: NSMenuItem {
    private let toggleState: WifiToggleState

    init(title: String, isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        self.toggleState = WifiToggleState(isOn: isOn)
        super.init(title: title, action: nil, keyEquivalent: "")
        let view = QuickToggleView(state: toggleState, title: title, onToggle: onToggle)
        self.view = NSHostingView(rootView: view)
        self.view?.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: 44)
    }

    func update(isOn: Bool) {
        toggleState.isOn = isOn
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
