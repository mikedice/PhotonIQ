//
//  ContentView.swift
//  test2025
//
//  Created by Mike Dice on 10/8/25.
//

import SwiftUI
import Foundation
import Combine


struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    var body: some View {
        BLEView(bleManager: bleManager)
    }
}

#Preview {
    ContentView()
}

