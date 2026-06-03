import SwiftUI
import Charts

struct SignalData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Int
}

class NetworkDetailsViewModel: ObservableObject {
    @Published var ssid: String = ""
    @Published var ipAddress: String = ""
    @Published var router: String = ""
    @Published var signal: Int = 0
    @Published var noise: Int = 0
    @Published var txRate: String = ""
    @Published var channel: String = ""
    @Published var phyMode: String = ""
    @Published var bssid: String = ""
    @Published var snr: Int = 0
    @Published var signalHistory: [SignalData] = (0..<30).map { index in
        SignalData(time: Date().addingTimeInterval(Double(-index * 2)), value: Int.random(in: -70...(-60)))
    }

    func update(with info: StatusMenuBase.StationInfo) {
        self.ssid = info.ssid ?? ""
        self.ipAddress = info.ipAddr
        self.router = info.routerAddr
        self.signal = info.rssiValue
        self.noise = Int(info.noise.replacingOccurrences(of: " dBm", with: "")) ?? 0
        self.txRate = info.txRate
        self.channel = info.channel
        self.phyMode = info.phyMode
        self.bssid = info.bssid
        self.snr = self.signal - self.noise

        let newData = SignalData(time: Date(), value: info.rssiValue)
        signalHistory.insert(newData, at: 0)
        if signalHistory.count > 30 {
            signalHistory.removeLast()
        }
    }
}

struct NetworkDetailsDashboard: View {
    @ObservedObject var viewModel: NetworkDetailsViewModel

    private var signalDisplay: String {
        if UserDefaults.standard.bool(forKey: String.DefaultsKey.showSignalAsPercentage) {
            let percentage = max(min(viewModel.signal + 100, 70), 0) * 100 / 70
            return "\(percentage)%"
        }
        return "\(viewModel.signal) dBm"
    }

    private var signalColor: Color {
        let rssi = viewModel.signal
        if rssi > -60 { return .green }
        if rssi > -75 { return Color(red: 1, green: 0.6, blue: 0) }
        return .red
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(signalColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "wifi", variableValue: Double(max(0, viewModel.signal + 100)) / 100.0)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(signalColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.ssid)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(signalColor)
                            .frame(width: 6, height: 6)
                        Text(String.Dashboard.connected)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(signalColor.opacity(0.8))
                    }
                }

                Spacer()

                // Tx Rate Badge
                VStack(alignment: .trailing, spacing: -2) {
                    Text(viewModel.txRate.replacingOccurrences(of: " Mbps", with: ""))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Mbps")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary.opacity(0.8))
                        .tracking(0.5)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(10)
            }
            .padding(.bottom, 14)

            // Signal Chart
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(String.Dashboard.signalStrength)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(0.8)
                    Spacer()
                    Text(signalDisplay)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(signalColor)
                }

                Chart {
                    ForEach(viewModel.signalHistory) { data in
                        AreaMark(
                            x: .value("Time", data.time),
                            y: .value("Signal", data.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [signalColor.opacity(0.3), signalColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)

                        LineMark(
                            x: .value("Time", data.time),
                            y: .value("Signal", data.value)
                        )
                        .foregroundStyle(signalColor.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .interpolationMethod(.monotone)
                    }
                }
                .chartYScale(domain: -90...(-30))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 36)
            }
            .padding(.bottom, 16)

            Divider().opacity(0.1)
                .padding(.bottom, 14)

            // Details Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailItem(label: String.Dashboard.ipAddress, value: viewModel.ipAddress, icon: "network")
                DetailItem(label: String.Dashboard.router, value: viewModel.router, icon: "wifi.router")
                DetailItem(
                    label: String.Dashboard.channel,
                    value: viewModel.channel,
                    icon: "antenna.radiowaves.left.and.right"
                )
                DetailItem(label: String.Dashboard.phyMode, value: viewModel.phyMode, icon: "bolt.fill")
                DetailItem(label: "BSSID", value: viewModel.bssid.uppercased(), icon: "macpro.gen3")
                DetailItem(label: String.Dashboard.noise, value: "\(viewModel.noise) dBm", icon: "ear.and.waveform")
                DetailItem(label: "SNR", value: "\(viewModel.snr) dB", icon: "equal.circle")
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 20, height: 20)
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(label.uppercased())
                    .font(.system(size: 7.5, weight: .black))
                    .foregroundColor(.secondary.opacity(0.5))
                    .tracking(0.6)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
        }
    }
}
