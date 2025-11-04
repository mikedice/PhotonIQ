//
//  PhotonIQApp.swift
//  PhotonIQ
//
//  Created by Mike Dice on 10/12/25.
//

import SwiftUI


extension ProcessInfo {
    var isRunningInXcodePreviews: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

@main
struct PhotonIQApp: App {
   
    var body: some Scene {
        WindowGroup {
            
            if ProcessInfo.processInfo.isRunningInXcodePreviews {
                ContentView(bleManager:  BLEManagerMock())
            }
            else {
                ContentView(bleManager: BLEManager())
            }
        }
    }
}
