import SwiftUI

struct ModernWiFiConfigView: View {
    let ssid: String
    @State private var password = ""
    @State private var showPassword = false
    @State private var rememberNetwork = true
    @State private var isConnecting = false

    var onJoin: (String, Bool) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .accentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "wifi")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Join \"\(ssid)\"")
                        .font(.system(size: 20, weight: .bold))
                    Text("Enter the password for this network.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(24)

            // Form Area
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack {
                        if showPassword {
                            TextField("Required", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                        } else {
                            SecureField("Required", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                        }

                        Button(action: { showPassword.toggle() }, label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }

                Toggle("Remember this network", isOn: $rememberNetwork)
                    .font(.system(size: 13))
                    .toggleStyle(CheckboxToggleStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Footer
            HStack(spacing: 12) {
                if isConnecting {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.large)

                Button("Join") {
                    isConnecting = true
                    onJoin(password, rememberNetwork)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .controlSize(.large)
                .disabled(password.count < 8 || isConnecting)
            }
            .padding(24)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 450, height: 320)
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow).ignoresSafeArea())
    }
}
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}
