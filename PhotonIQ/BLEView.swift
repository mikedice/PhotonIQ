//
//  PostsView.swift
//  test2025
//
//  Created by Mike Dice on 10/9/25.
//

import SwiftUI
import Foundation
import Combine
import CoreBluetooth
import Charts

struct BLEView : View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        NavigationView {
            VStack {
                Text(bleManager.isScanning ? "🔍 Scanning..." : "🛑 Not scanning")
                    .font(.headline)
                    .padding()

                if let connected = bleManager.connectedPeripheral {
                    Text("✅ Connected to: \(connected.name ?? "Unnamed")")
                        .foregroundColor(.green)
                        .padding(.bottom)
                }

                List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                    HStack {
                        Text(peripheral.name ?? "Unknown Device")
                        Spacer()
                        if peripheral == bleManager.connectedPeripheral {
                            Text("🟢 Connected")
                        }
                    }
                }
                
                if bleManager.wifiSSIDScanCommandCharacteristic != nil {
                    NavigationLink("Configure Wi-Fi") {
                        ConfigureWifiView(bleManager: bleManager)
                    }
                    .padding()
                }
                
                Text("💡 Light Level: \(bleManager.lightLevel)")
                    .font(.title2)                  // Slightly smaller than largeTitle
                    .monospacedDigit()             // Keep digits from jumping
                    .lineLimit(1)                  // Prevent wrapping
                    .minimumScaleFactor(0.7)       // Shrink if too long
                    .padding(.bottom)
                
                Chart(bleManager.lightHistory) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Light", point.value)
                    )
                }
                .frame(height: 200)
                .padding()

                Button(action: {
                    bleManager.isScanning ? bleManager.stopScan() : bleManager.startScan()
                }) {
                    Text(bleManager.isScanning ? "Stop Scan" : "Start Scan")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(bleManager.isScanning ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("PhotonIQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("PhotonIQ")
                            .font(.headline)
                        Text("Intelligent Light Sensor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

