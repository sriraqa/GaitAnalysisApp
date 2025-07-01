//
//  ContentView.swift
//  GaitAnalysisApp
//
//  Created by Sarah Qiao on 2025-06-19.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var bluetoothManager = BLEManager()
    @State var mirror: [(String, Int)]? = nil
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if bluetoothManager.peripherals.isEmpty {
                ProgressView("Searching for ESP32 Module")
                    .progressViewStyle(.circular)
            } else if bluetoothManager.isConnected {
                Text("Force Sensor Values:")
                    .font(.system(size: 24))
                    .bold()
                VStack(spacing: 8) {
                    if let values = mirror {
                        ForEach(values, id: \.0) { label, number in
                            Text("\(label): \(number)")
                                .foregroundColor(getColor(for: number))
                        }
                    }
                }
                Spacer()
                List {
                    Button("Disconnect") {
                        bluetoothManager.disconnectFromPeripheral()
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .onAppear {
                    mirror = [
                        ("Big Toe", 0),
                        ("Ball", 0),
                        ("Sole", 0),
                        ("Arch", 0),
                        ("Heel", 0)
                    ]
                }
            } else {
                List(bluetoothManager.peripherals) { peripheral in
                    device(peripheral)
                }
                .refreshable {
                    bluetoothManager.refreshDevices()
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
        .onChange(of: bluetoothManager.forceLevel) { forceData in
            mirror = [
                ("Big Toe", forceData.big_toe),
                ("Ball", forceData.ball),
                ("Sole", forceData.sole),
                ("Arch", forceData.arch),
                ("Heel", forceData.heel)
            ]
        }
    }
    
    func device(_ peripheral: Peripheral) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(peripheral.name)
                Spacer()
                Button(action: {
                    bluetoothManager.connectPeripheral(peripheral: peripheral)
                }) {
                    Text("Connect")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            VStack(alignment: .leading) {
                Group {
                    Text("""
                          Device UUID:
                          \(peripheral.id.uuidString)
                          """)
                    .padding([.bottom], 10)

                    if let adsServiceUUIDs = peripheral.advertisementServiceUUIDs {
                        Text("Advertisement Service UUIDs:")
                        ForEach(adsServiceUUIDs, id: \.self) { uuid in
                            Text(uuid)
                        }
                    }

                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("\(peripheral.rssi) dBm")
                    }
                    .padding([.top], 10)
                }
                .font(.footnote)
            }
        }
    }
    
    func getColor(for value: Int) -> Color {
        switch value {
        case ..<50:
            return .green
        case 50..<150:
            return .yellow
        case 150..<300:
            return .orange
        default:
            return .red
        }
    }
}
