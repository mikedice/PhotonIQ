# Photon IQ 🌞📡

**Photon IQ** is a smart light-sensing app built with SwiftUI and powered by an ESP32-S3 hardware module.  
It combines Bluetooth Low Energy (BLE) and Wi-Fi connectivity to measure, analyze, and visualize ambient light in real time.

---

## ✨ Features
- **Live Light Graph** – View real-time lux readings from your Photon IQ sensor.  
- **BLE + Wi-Fi Dual Mode** – Configure and stream data simultaneously.  
- **Wi-Fi Setup via BLE** – Scan and select nearby access points directly from the app.  
- **Edge AI Ready** – Future support for on-device anomaly detection and light-pattern prediction.  
- **SwiftUI Interface** – Modern iOS design with live previews and animations.

---

## 🧠 Architecture
| Layer | Description |
|-------|--------------|
| **Hardware** | Arduino Nano ESP32 (S3) with TSL2591 light sensor |
| **BLE Manager** | Handles connection, services, and notifications |
| **SwiftUI Views** | `BLEView`, `ConfigureWiFiView`, `LightGraphView` |
| **Data Model** | `LightDataPoint` struct for time-stamped readings |
| **Networking** | Future module for MQTT / REST cloud sync |

---

## 🧩 Getting Started
1. Clone the repo  
   ```bash
   git clone https://github.com/mikedice/PhotonIQ.git
   ```
2. Open `PhotonIQ.xcodeproj` in Xcode 15 or later.  
3. Build & run on an iPhone with BLE enabled.  
4. Power on your Photon IQ sensor and pair via the app.

---

## 🛠️ Hardware Setup
| Component | Connection |
|------------|-------------|
| **TSL2591 Light Sensor** | I²C (SDA=A4, SCL=A5) |
| **ESP32-S3 Board** | Arduino Nano ESP32 (ABX00083) |
| **Optional RTC / SD Card** | SPI or I²C as needed |

---

## 🧭 Roadmap
- [ ] Cloud sync via Wi-Fi  
- [ ] OTA firmware updates  
- [ ] On-device AI inference (TensorFlow Lite Micro)  
- [ ] App Store release  

---

## 🪪 License
MIT License © 2025 Mike Dice

---

> *“Intelligence at the speed of light.”*
