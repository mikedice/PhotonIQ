import Foundation
import CoreBluetooth
import Combine

struct LightDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

@MainActor
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
//    var objectWillChange = ObservableObjectPublisher()
    
    private var centralManager: CBCentralManager!
    @Published var isScanning = false
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var lightLevel: String = "?"
    @Published var lightHistory: [LightDataPoint] = []
    
    @Published var wifiNetworks: [String] = []
    let wifiServiceUUID = CBUUID(string: "458800E6-FC10-46BD-8CDA-7F0F74BB1DBF")
    let wifiSSIDsCharacteristicUUID = CBUUID(string: "B30041A1-23DF-473A-AEEC-0C8514514B03")
    let wifiSSIDScanCommandCharacteristicUUID  = CBUUID(string: "5F8B1E42-1A56-4B5A-8026-8B15BC7EE5F3")
    var wifiSSIDsCharacteristic: CBCharacteristic?
    @Published var wifiSSIDScanCommandCharacteristic: CBCharacteristic?
    
    
    let lightServiceCBUUID = CBUUID(string: "3d80c0aa-56b9-458f-82a1-12ce0310e076")
    var lightCharacteristic: CBCharacteristic!;
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        } else {
            print("Bluetooth is not available")
        }
    }

    func startScan() {
        DispatchQueue.main.async {
            self.isScanning = true
        }

        centralManager.scanForPeripherals(withServices: [lightServiceCBUUID], options: nil)
        print("🔍 Scanning for peripherals")
    }

    func stopScan() {
        isScanning = false
        centralManager.stopScan()
        print("🛑 Stopped scanning")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("🛰️ Found: \(peripheral.name ?? "Unknown")")

            // Auto-connect to the first one
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to \(peripheral.name ?? "Unknown")")
        peripheral.delegate = self
        peripheral.discoverServices([lightServiceCBUUID, wifiServiceUUID])
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ Disconnected from \(peripheral.name ?? "Unknown")")
        DispatchQueue.main.async {
            self.connectedPeripheral = nil
            self.lightLevel = "?"
            self.lightHistory = []
        }

        // Optional: try reconnecting
        centralManager.connect(peripheral, options: nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("✅ found service \(service.uuid)")
            if service.uuid == lightServiceCBUUID {
                peripheral.discoverCharacteristics([CBUUID(string: "646bd4e2-0927-45ac-bf41-fd9c69aa31dd")], for: service)
            }
            if service.uuid == wifiServiceUUID {
                peripheral.discoverCharacteristics([wifiSSIDScanCommandCharacteristicUUID, wifiSSIDsCharacteristicUUID], for: service)
            }
            print("📡 Discovered service: \(service.uuid)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("🔑 Found characteristic: \(characteristic.uuid)")
            if characteristic.uuid == CBUUID(string: "646bd4e2-0927-45ac-bf41-fd9c69aa31dd") {
                self.lightCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
            }
            if characteristic.uuid == wifiSSIDScanCommandCharacteristicUUID {
                self.wifiSSIDScanCommandCharacteristic = characteristic
            }
            if characteristic.uuid == wifiSSIDsCharacteristicUUID {
                self.wifiSSIDsCharacteristic = characteristic
            }
            
            // Subscribe if it's not write-only
            //if characteristic.properties.contains(.notify) {
            //    peripheral.setNotifyValue(true, for: characteristic)
            //}

            // Read initial value
            //if characteristic.properties.contains(.read) {
            //    peripheral.readValue(for: characteristic)
            //}
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //guard let value = characteristic.value else { return }
        //let bytes = [UInt8](value)
        //print("📬 Received data: \(bytes) from \(characteristic.uuid)")
        // TODO: decode and publish to your UI
        if characteristic.uuid == CBUUID(string: "646bd4e2-0927-45ac-bf41-fd9c69aa31dd") {
            
            if let value = characteristic.value {
                // Example: convert data to string or integer
                let lightLevelString = String(data: value, encoding: .utf8) ?? "?"
                print("💡 Light Sensor Data: \(lightLevelString)")
                DispatchQueue.main.async {
                    self.lightLevel = lightLevelString
                    self.appendLightLevel(lightLevelString)
                }
                
            }
        }
        if characteristic.uuid == wifiSSIDsCharacteristicUUID {
            if let value = characteristic.value {
                let wifiSSIDsString = String(data: value, encoding: .utf8) ?? "?"
                print("🔍 WiFi SSIDs: \(wifiSSIDsString)")
                DispatchQueue.main.async {
                    // wifiSSIDsString is a comma separated list of string.
                    let ssids = wifiSSIDsString
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    self.wifiNetworks = ssids
                }
                
            }
        }
    }
    
    func sendWifiScanCommand(){
        guard let peripheral = connectedPeripheral,
              let cmd = wifiSSIDScanCommandCharacteristic else {
                  print("couldn't send wifi scan command")
                  return }
        var val: UInt8 = 1    // true for “start scan”
        let data = Data(bytes: &val, count: 1)
        peripheral.writeValue(data, for: cmd, type: .withResponse)
        print("📤 Sent Wi-Fi scan trigger")
    }
    
    private func appendLightLevel(_ string: String) {
        // Remove the "lux" label and trim whitespace
        let clean = string
            .replacingOccurrences(of: "lux", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let doubleVal = Double(clean) {
            let point = LightDataPoint(timestamp: Date(), value: doubleVal)
            lightHistory.append(point)

            // Limit to last N points
            if lightHistory.count > 100 {
                lightHistory.removeFirst()
            }
        } else {
            print("⚠️ Could not parse light level from '\(string)' → '\(clean)'")
        }
    }
}

