//
//  BLEManagerProtocol.swift
//  PhotonIQ
//
//  Created by Mike Dice on 11/3/25.
//

import Foundation

protocol BLEManagerProtocol : ObservableObject
{
    var isScanning: Bool { get }
    var dicoveredPeripheralInfo: [UUID: String] { get }
    var connectedPeriperalUUID: UUID? { get }
    var connectedPeripheralName: String? { get }
    var lightLevel: String { get }
    var lightHistory: [LightDataPoint] { get }
    var wifiNetworks: [String] { get }
    var isScanningWifi: Bool { get }
    var isWifiConnected: Bool { get }
    var wifiConnectedToSSID: String { get}
    var canConfigureWifi: Bool { get }
    func startWifiScan()
    func sendWifiCredentials(ssid: String, password: String)
}
