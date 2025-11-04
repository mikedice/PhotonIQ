//
//  ContentView.swift
//  test2025
//
//  Created by Mike Dice on 10/8/25.
//

import SwiftUI
import Foundation
import Combine


struct ContentView<Manager: BLEManagerProtocol>: View {
    @StateObject private var bleManager: Manager
    
    init(bleManager: Manager) {
        self._bleManager = StateObject(wrappedValue: bleManager)
    }
    
    var body: some View {
       BLEView(bleManager: bleManager)
    }
}

#Preview {
    
    ContentView(bleManager: BLEManagerMock())
}

