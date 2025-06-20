//
//  ContentView.swift
//  GaitAnalysisApp
//
//  Created by Sarah Qiao on 2025-06-19.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Force Sensor Value:")
            Text("\(bluetoothManager.forceLevel)")
                .foregroundColor(bluetoothManager.forceLevel < 10 ? .green : .red)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
