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
                if bleManager.isScanning {
                    Text("🔍 Scanning...")
                        .font(.headline)
                        .padding()
                }

                if let name = bleManager.connectedPeripheralName {
                    Text("✅ Connected to: \(name)")
                        .foregroundColor(.green)
                        .padding(.bottom)

                    HStack(spacing: 8) {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(bleManager.isWifiConnected ? .green : .red)
                        if bleManager.isWifiConnected {
                            Text("WiFi: \(bleManager.wifiConnectedToSSID.isEmpty ? "(SSID unknown)" : bleManager.wifiConnectedToSSID)")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("WiFi Not connected")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                    .padding(.bottom, 8)
                }

                // if bleManager.wifiSSIDScanCommandCharacteristic != nil {
                if bleManager.canConfigureWifi {
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

                if !bleManager.isScanning {
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

