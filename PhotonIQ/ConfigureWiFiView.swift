import SwiftUI

struct ConfigureWifiView: View {
    @ObservedObject var bleManager: BLEManager
    @Environment(\.dismiss) private var dismiss

    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Configure Device Wi-Fi")
                .font(.title2)

            Button {
                bleManager.sendWifiScanCommand()
                isScanning = true
            } label: {
                Text(isScanning ? "Scanning…" : "Start Scan")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isScanning ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isScanning)
            .padding(.horizontal)

            if !bleManager.wifiNetworks.isEmpty {
                List(bleManager.wifiNetworks, id: \.self) { ssid in
                    Text(ssid)
                }
                .listStyle(.inset)
            } else if isScanning {
                ProgressView("Searching for networks…")
                    .padding()
            }

            Spacer()

            Button("Done") { dismiss() }
                .padding(.bottom)
        }
        .padding()
    }
}
