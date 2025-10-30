import SwiftUI

struct ConfigureWifiView: View {
    @ObservedObject var bleManager: BLEManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSSID: String? = nil
    @State private var wifiPassword: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Configure Device Wi-Fi")
                .font(.title2)

            if bleManager.isWifiConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .foregroundStyle(.green)
                    Text("Connected to Wi‑Fi \(bleManager.wifiConnectedToSSID)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            }

            Button {
                bleManager.startWifiScan()
            } label: {
                Text(bleManager.isScanningWifi ? "Scanning…" : "Start Scan")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(bleManager.isScanningWifi ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(bleManager.isScanningWifi)
            .padding(.horizontal)

            if !bleManager.wifiNetworks.isEmpty {
                List(bleManager.wifiNetworks, id: \.self) { ssid in
                    HStack {
                        Text(ssid)
                        if selectedSSID == ssid {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSSID = ssid
                    }
                }
                .listStyle(.inset)
            } else if bleManager.isScanningWifi {
                ProgressView("Searching for networks…")
                    .padding()
            }

            if let ssid = selectedSSID {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Use this Wi‑Fi Network").font(.headline)
                    Text("SSID: \(ssid)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SecureField("Password", text: $wifiPassword)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    Button {
                        bleManager.sendWifiCredentials(ssid: ssid, password: wifiPassword)
                    } label: {
                        Text("Send Credentials")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(ssid.isEmpty)
                }
                .padding()
                .transition(.opacity)
            }

            Spacer()

            Button("Done") { dismiss() }
                .padding(.bottom)
        }
        .padding()
    }
}
