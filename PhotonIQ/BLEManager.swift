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

// TODO: It seems like it shoudl be simple to inject this Mock BLE manager into the view
// but turns out to be not so easy. Find a way to inject or remove this.
@MainActor
class MockBLEManager : NSObject, ObservableObject, BLEManagerProtocol
{
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

@MainActor
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, BLEManagerProtocol
{
    // BLEManagerProtocol implementation
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
    @Published private(set) var canConfigureWifi: Bool = false // private(set) to avoid someone setting this from outside

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var wifiSSIDsCharacteristic: CBCharacteristic!
    private var wifiSSIDScanCommandCharacteristic: CBCharacteristic? {
        didSet {
            canConfigureWifi = (wifiSSIDScanCommandCharacteristic != nil)
        }
    }
    

    var wifiConnectedSSIDCharacteristic: CBCharacteristic?
    var wifiConnectedStatusCharacteristic: CBCharacteristic?
    var lightCharacteristic: CBCharacteristic?;
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
        centralManager.scanForPeripherals(withServices: [PhotonUUIDs.Services.light], options: nil)
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
        peripheral.discoverServices([PhotonUUIDs.Services.light,
                                     PhotonUUIDs.Services.wifi,
                                     PhotonUUIDs.Services.settings])
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
            
            if service.uuid == PhotonUUIDs.Services.light {
                print("📡 Discovered light service service (\(service.uuid))")
                peripheral.discoverCharacteristics([PhotonUUIDs.Characteristics.lightLevel], for: service)
            }
            else if service.uuid == PhotonUUIDs.Services.wifi {
                print("📡 Discovered WiFi service (\(service.uuid))")
                peripheral.discoverCharacteristics([PhotonUUIDs.Characteristics.wifiScanCommand,
                                                    PhotonUUIDs.Characteristics.wifiSSIDs,
                                                    PhotonUUIDs.Characteristics.wifiConnectedSSID,
                                                    PhotonUUIDs.Characteristics.wifiConnectedStatus],
                                                   for: service)
            }
            else if service.uuid == PhotonUUIDs.Services.settings  {
                print("📡 Discovered settings service (\(service.uuid))")
                peripheral.discoverCharacteristics([
                    PhotonUUIDs.Characteristics.sensorName,
                    PhotonUUIDs.Characteristics.scanInterval,
                    PhotonUUIDs.Characteristics.wifiSSIDAndPassword,
                    PhotonUUIDs.Characteristics.wifiEnabled
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
            if characteristic.uuid == PhotonUUIDs.Characteristics.lightLevel {
                print("🔑 Found light characteristic: (\(characteristic.uuid))")
                self.lightCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiScanCommand {
                print("🔑 Found WiFi Scan characteristic: (\(characteristic.uuid))")
                print("🔑 WiFi Scan characteristic props: \(characteristic.properties)")
                self.wifiSSIDScanCommandCharacteristic = characteristic
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiSSIDs {
                print("🔑 Found WiFi SSIDs list characteristic: (\(characteristic.uuid))")
                self.wifiSSIDsCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiConnectedSSID{
                print("🔑 Found WiFi Connected SSID characteristic: (\(characteristic.uuid))")
                self.wifiConnectedSSIDCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiConnectedStatus {
                print("🔑 Found WiFi Connected Status characteristic: (\(characteristic.uuid))")
                self.wifiConnectedStatusCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.sensorName {
                print("🔑 Found Sensor Name characteristic: (\(characteristic.uuid))")
                self.sensorNameCharacteristic = characteristic
            }
            else if characteristic.uuid ==  PhotonUUIDs.Characteristics.scanInterval {
                print("🔑 Found Scan Interval characteristic: (\(characteristic.uuid))")
                self.scanIntervalCharacteristic = characteristic
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiSSIDAndPassword {
                print("🔑 Found WiFi Set SSID characteristic: (\(characteristic.uuid))")
                self.wifiSSIDandPassword = characteristic
            }
            else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiEnabled {
                print("🔑 Found WiFi Enable characteristic: (\(characteristic.uuid))")
                self.wifiEnabledCharacteristic = characteristic
            }
            else {
                print("🔑 Found unknown characteristic: (\(characteristic.uuid))")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if characteristic.uuid == PhotonUUIDs.Characteristics.lightLevel {
            
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
        else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiSSIDs {
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
        else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiConnectedSSID {
            if let value = characteristic.value {
                self.wifiConnectedToSSID = String(data:value, encoding: .utf8) ?? "?"
            }
        }
        else if characteristic.uuid == PhotonUUIDs.Characteristics.wifiConnectedStatus {
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
        if characteristic.uuid == PhotonUUIDs.Characteristics.wifiScanCommand {
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

