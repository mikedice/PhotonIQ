import CoreBluetooth

enum PhotonUUIDs {
    
    enum Services {
        static let wifi = CBUUID(string: "458800E6-FC10-46BD-8CDA-7F0F74BB1DBF")
        static let light = CBUUID(string: "3D80C0AA-56B9-458F-82A1-12CE0310E076")
        static let settings = CBUUID(string: "C1D5A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
    }

    enum Characteristics {
        static let wifiSSIDs = CBUUID(string: "B30041A1-23DF-473A-AEEC-0C8514514B03")
        static let wifiScanCommand = CBUUID(string: "5F8B1E42-1A56-4B5A-8026-8B15BC7EE5F3")
        static let wifiConnectedSSID = CBUUID(string: "A1B2C3D4-E5F6-4789-ABCD-EF0123456789")
        static let wifiConnectedStatus = CBUUID(string: "12345678-9ABC-DEF0-1234-56789ABCDEF0")
        static let lightLevel = CBUUID(string: "646BD4E2-0927-45AC-BF41-FD9C69AA31DD")
        static let sensorName = CBUUID(string: "D2C1A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
        static let scanInterval = CBUUID(string: "E3F4B5C6-8D9E-4F0A-B1C2-D3E4F5A6B7C8")
        static let wifiSSIDAndPassword = CBUUID(string: "B2C1A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
        static let wifiEnabled = CBUUID(string: "D3C1A3B2-7E2F-4F4C-9F1D-3A2B1C0D4E5F")
    }
}