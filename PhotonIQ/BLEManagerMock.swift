//
//  BLEManagerMock.swift
//  PhotonIQ
//
//  Created by Mike Dice on 11/3/25.
//

import Foundation
import Combine

@MainActor
class BLEManagerMock : NSObject, ObservableObject, BLEManagerProtocol
{
    func startWifiScan() {
        print("Mock start wifi scan")
    }
    
    func sendWifiCredentials(ssid: String, password: String) {
        print("Mock send Wifi Credentials")
    }
    
    @Published var isScanning: Bool = false
    @Published var dicoveredPeripheralInfo: [UUID: String] = [:]
    @Published var connectedPeriperalUUID: UUID? = nil
    @Published var connectedPeripheralName: String? = nil
    @Published var lightLevel: String = "?"
    @Published var lightHistory: [LightDataPoint] = []
    @Published var wifiNetworks: [String] = []
    @Published var isScanningWifi: Bool = false
    @Published var isWifiConnected: Bool = false
    @Published var wifiConnectedToSSID: String = ""
    @Published var canConfigureWifi: Bool = true
}
