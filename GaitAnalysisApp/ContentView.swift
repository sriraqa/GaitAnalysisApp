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
    @State var mirror: [Int] = []
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if bluetoothManager.peripherals.isEmpty {
                ProgressView("Searching for ESP32 Module")
                    .progressViewStyle(.circular)
            } else if bluetoothManager.isConnected {
//                Diagram
                ZStack {
                    Rectangle()
                        .fill((Color.gray))
                        .frame(width: 190, height: 500)
                    VStack {
                        HStack {
    //                        Toe
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? mirror[0] : 0)), .gray]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .padding([.leading], 60)
                            Spacer()
                        }
                        .padding([.horizontal], 16)
                        HStack(spacing: 2) {
    //                        Right Ball
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? mirror[1] : 0)), .gray]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
    //                        Left Ball
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? mirror[2] : 0)), .gray]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                        }
    //                    Arch
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? mirror[3] : 0)), .gray]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .padding([.top], 20)
                            .padding([.leading], 40)
    //                    Heel
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? mirror[4] : 0)), .gray]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .padding([.top, .trailing], 40)
                    }
                }
                    .mask(
                        Image("foot_outline")
                            .resizable()
                            .frame(width: 190, height: 500)
                    )
                Spacer()
                List {
                    Button("Disconnect") {
                        bluetoothManager.disconnectFromPeripheral()
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .onAppear {
                    mirror = []
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
                forceData.big_toe,
                forceData.ball,
                forceData.sole,
                forceData.arch,
                forceData.heel
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
        // Clamp value to 0...300
        let clamped = min(max(value, 0), 300)

        // Define the color stops: Green (0), Yellow (150), Red (300)
        let green = SIMD3<Double>(0.0, 1.0, 0.0)
        let yellow = SIMD3<Double>(1.0, 1.0, 0.0)
        let red = SIMD3<Double>(1.0, 0.0, 0.0)

        let resultRGB: SIMD3<Double>

        if clamped <= 150 {
            // Interpolate between green and yellow
            let t = clamped / 150
            resultRGB = linearInterpolate(a: green, b: yellow, t: Double(t))
        } else {
            // Interpolate between yellow and red
            let t = (clamped - 150) / 150
            resultRGB = linearInterpolate(a: yellow, b: red, t: Double(t))
        }

        return Color(
            red: resultRGB.x,
            green: resultRGB.y,
            blue: resultRGB.z
        )
    }
    
    func linearInterpolate(a: SIMD3<Double>, b: SIMD3<Double>, t: Double) -> SIMD3<Double> {
        return a + (b - a) * t
    }
}
