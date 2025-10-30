import Foundation
import CoreBluetooth
import Combine

struct LightDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

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
}

@MainActor
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, BLEManagerProtocol
{
    
    private var centralManager: CBCentralManager!
    @Published var isScanning = false
    @Published var dicoveredPeripheralInfo: [UUID: String] = [:]
    @Published var connectedPeriperalUUID: UUID? = nil
    @Published var connectedPeripheralName: String? = nil
    @Published var lightLevel: String = "?"
    @Published var lightHistory: [LightDataPoint] = []
    @Published var wifiNetworks: [String] = []
    @Published var isScanningWifi = false
    @Published var isWifiConnected = false
    @Published var wifiConnectedToSSID = ""
    @Published private(set) var canConfigureWifi: Bool = false
    
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var wifiSSIDsCharacteristic: CBCharacteristic!
    private var wifiSSIDScanCommandCharacteristic: CBCharacteristic? {
        didSet {
            canConfigureWifi = (wifiSSIDScanCommandCharacteristic != nil)
        }
    }
    
    let wifiServiceUUID = CBUUID(string: "458800E6-FC10-46BD-8CDA-7F0F74BB1DBF")
    let wifiSSIDsCharacteristicUUID = CBUUID(string: "B30041A1-23DF-473A-AEEC-0C8514514B03")
    let wifiSSIDScanCommandCharacteristicUUID  = CBUUID(string: "5F8B1E42-1A56-4B5A-8026-8B15BC7EE5F3")
    let wifiConnectedSSIDCharacteristicUUID = CBUUID(string: "A1B2C3D4-E5F6-4789-ABCD-EF0123456789")
    let wifiConnectedStatusCharacteristicUUID = CBUUID(string: "12345678-9ABC-DEF0-1234-56789ABCDEF0")
    let lightServiceCBUUID = CBUUID(string: "3d80c0aa-56b9-458f-82a1-12ce0310e076")
    let lightCharacteristicUUID = CBUUID(string:"646bd4e2-0927-45ac-bf41-fd9c69aa31dd")
    let settingsServiceUUID = CBUUID(string:"C1D5A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
    let sensorNameCharacteristicUUID = CBUUID(string:"D2C1A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
    let scanIntervalCharacteristicUUID = CBUUID(string:"E3F4B5C6-8D9E-4F0A-B1C2-D3E4F5A6B7C8")
    let wifiSSIDAndPasswordCharacteristicUUID = CBUUID(string:"B2C1A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
    let wifiEnabledCharacteristicUUID = CBUUID(string:"D3C1A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")

    var wifiConnectedSSIDCharacteristic: CBCharacteristic!
    var wifiConnectedStatusCharacteristic: CBCharacteristic!
    var lightCharacteristic: CBCharacteristic!;
    var sensorNameCharacteristic: CBCharacteristic?
    var scanIntervalCharacteristic: CBCharacteristic?
    var wifiSSIDandPassword: CBCharacteristic?
    var wifiEnabledCharacteristic: CBCharacteristic?
    
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
        self.isScanning = true
        centralManager.scanForPeripherals(withServices: [lightServiceCBUUID], options: nil)
        print("🔍 Scanning for peripherals")
    }

    func stopScan() {
        isScanning = false
        centralManager.stopScan()
        print("🛑 Stopped scanning")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let identifier = peripheral.identifier
        let name = peripheral.name ?? "Unknown"
        if dicoveredPeripheralInfo[identifier] == nil {
            dicoveredPeripheralInfo[identifier] = name
            discoveredPeripherals.append(peripheral) // note if we don't hang onto a reference to the peripheral it will disconenct
            print("🛰️ Found: \(name) with identifier \(identifier)")

            // Auto-connect to the first one
            centralManager.connect(peripheral, options: nil)
        } else {
            print("Already discovered: \(name)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to \(peripheral.name ?? "Unknown")")
        stopScan()
        peripheral.delegate = self
        peripheral.discoverServices([lightServiceCBUUID, wifiServiceUUID, settingsServiceUUID])
        self.connectedPeripheral = peripheral
        self.connectedPeriperalUUID = peripheral.identifier
        self.connectedPeripheralName = peripheral.name ?? "Unknown"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ Disconnected from \(peripheral.name ?? "Unknown")")

        self.connectedPeripheral = nil
        self.wifiSSIDScanCommandCharacteristic = nil
        self.lightLevel = "?"
        self.lightHistory = []

        // Optional: try reconnecting
        centralManager.connect(peripheral, options: nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            
            if service.uuid == lightServiceCBUUID {
                print("📡 Discovered light service service (\(service.uuid))")
                peripheral.discoverCharacteristics([lightCharacteristicUUID], for: service)
            }
            else if service.uuid == wifiServiceUUID {
                print("📡 Discovered WiFi service (\(service.uuid))")
                peripheral.discoverCharacteristics([wifiSSIDScanCommandCharacteristicUUID,
                                                    wifiSSIDsCharacteristicUUID,
                                                    wifiConnectedSSIDCharacteristicUUID,
                                                    wifiConnectedStatusCharacteristicUUID
                                                   ], for: service)
            }
            else if service.uuid == settingsServiceUUID {
                print("📡 Discovered settings service (\(service.uuid))")
                peripheral.discoverCharacteristics([
                    sensorNameCharacteristicUUID,
                    scanIntervalCharacteristicUUID,
                    wifiSSIDAndPasswordCharacteristicUUID,
                    wifiEnabledCharacteristicUUID
                ], for: service)
            }
            else{
                print("Found unknown service \(service.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == lightCharacteristicUUID {
                print("🔑 Found light characteristic: (\(characteristic.uuid))")
                self.lightCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
            }
            else if characteristic.uuid == wifiSSIDScanCommandCharacteristicUUID {
                print("🔑 Found WiFi Scan characteristic: (\(characteristic.uuid))")
                print("🔑 WiFi Scan characteristic props: \(characteristic.properties)")
                self.wifiSSIDScanCommandCharacteristic = characteristic
            }
            else if characteristic.uuid == wifiSSIDsCharacteristicUUID {
                print("🔑 Found WiFi SSIDs list characteristic: (\(characteristic.uuid))")
                self.wifiSSIDsCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.uuid == wifiConnectedSSIDCharacteristicUUID{
                print("🔑 Found WiFi Connected SSID characteristic: (\(characteristic.uuid))")
                self.wifiConnectedSSIDCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.uuid == wifiConnectedStatusCharacteristicUUID {
                print("🔑 Found WiFi Connected Status characteristic: (\(characteristic.uuid))")
                self.wifiConnectedStatusCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.uuid == sensorNameCharacteristicUUID {
                print("🔑 Found Sensor Name characteristic: (\(characteristic.uuid))")
                self.sensorNameCharacteristic = characteristic
            }
            else if characteristic.uuid == scanIntervalCharacteristicUUID {
                print("🔑 Found Scan Interval characteristic: (\(characteristic.uuid))")
                self.scanIntervalCharacteristic = characteristic
            }
            else if (characteristic.uuid == wifiSSIDAndPasswordCharacteristicUUID)
            {
                print("🔑 Found WiFi Set SSID characteristic: (\(characteristic.uuid))")
                self.wifiSSIDandPassword = characteristic
            }
            else if characteristic.uuid == wifiEnabledCharacteristicUUID{
                print("🔑 Found WiFi Enable characteristic: (\(characteristic.uuid))")
                self.wifiEnabledCharacteristic = characteristic
            }
            else {
                print("🔑 Found unknown characteristic: (\(characteristic.uuid))")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if characteristic.uuid == lightCharacteristicUUID {
            
            if let value = characteristic.value {
                // Example: convert data to string or integer
                let lightLevelString = String(data: value, encoding: .utf8) ?? "?"
                // print("💡 Light Sensor Data: \(lightLevelString)")
                DispatchQueue.main.async {
                    self.lightLevel = lightLevelString
                    self.appendLightLevel(lightLevelString)
                }
                
            }
        }
        else if characteristic.uuid == wifiSSIDsCharacteristicUUID {
            if let value = characteristic.value {
                let wifiSSIDsString = String(data: value, encoding: .utf8) ?? "?"
                print("🔍 WiFi SSIDs: \(wifiSSIDsString)")
                let ssids = wifiSSIDsString
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                self.wifiNetworks = ssids
                self.isScanningWifi = false

            }
        }
        else if characteristic.uuid == wifiConnectedSSIDCharacteristicUUID {
            if let value = characteristic.value {
                self.wifiConnectedToSSID = String(data:value, encoding: .utf8) ?? "?"
            }
        }
        else if characteristic.uuid == wifiConnectedStatusCharacteristicUUID {
            if let value = characteristic.value {
                // sensor sends "1" if it is connected or "0" if it is not
                self.isWifiConnected = String(data: value, encoding: .utf8) == "1" ? true : false;
            }
        }
    }
    
    func startWifiScan() {
        // Clear any existing results before starting a new scan
        wifiNetworks.removeAll()
        isScanningWifi = true
        sendWifiScanCommand()
    }
    
    func sendWifiScanCommand(){
        guard let peripheral = connectedPeripheral,
              let cmd = wifiSSIDScanCommandCharacteristic else {
            print("couldn't send wifi scan command")
            return
        }
        print("sending commandto peripheral \(peripheral.name ?? "unknown") \(peripheral.identifier)")

        // Prepare payload
        var val: UInt8 = 1
        let data = Data(bytes: &val, count: 1)

        // Choose correct write type based on properties
        let type: CBCharacteristicWriteType = cmd.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        print("✍️ Using write type: \(type == .withResponse ? "withResponse" : "withoutResponse")")

        peripheral.writeValue(data, for: cmd, type: type)
        self.isScanningWifi = true

    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == wifiSSIDScanCommandCharacteristicUUID {
            if let error = error {
                print("❗️Wi‑Fi scan write failed: \(error)")
                self.isScanningWifi = false
            } else {
                print("✅ Wi‑Fi scan write confirmed")
                self.isScanningWifi = true
            }
        }
    }
    
    func sendWifiCredentials(ssid: String, password: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = wifiSSIDandPassword else {
            print("❗️Cannot send Wi‑Fi credentials: missing peripheral or characteristic")
            return
        }

        // Define a simple payload format: "SSID\nPASSWORD"
        let payloadString = "\(ssid),\(password)"
        guard let data = payloadString.data(using: .utf8) else {
            print("❗️Failed to encode Wi‑Fi credentials")
            return
        }

        let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        print("📤 Sending Wi‑Fi credentials for SSID: \(ssid) using \(type == .withResponse ? "withResponse" : "withoutResponse")")
        peripheral.writeValue(data, for: characteristic, type: type)
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

