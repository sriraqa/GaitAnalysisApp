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
    @State var mirror: [String] = []
    
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
                                        gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? Int(mirror[0])! : 0)), .gray]),
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
    //                        Ball
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? Int(mirror[1])! : 0)), .gray]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
    //                        Sole
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? Int(mirror[2])! : 0)), .gray]),
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
                                    gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? Int(mirror[3])! : 0)), .gray]),
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
                                    gradient: Gradient(colors: [getColor(for: (!mirror.isEmpty ? Int(mirror[4])! : 0)), .gray]),
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
                // Fall detection notification conditionally appears
                if (bluetoothManager.isFall == true) {
                    Button(action: {
                        let numberString = "911"
                        let telephone = "tel://"
                        let formattedString = telephone + numberString
                        guard let url = URL(string: formattedString) else { return }
                        UIApplication.shared.open(url)
                       }) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.white)
                        Text("You have fallen! Press to call 911")
                            .bold()
                            .foregroundStyle(Color.white)
                    }
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.690, green: 0.149, blue: 0.082)))
                        .frame(width: 400, height: 80)

                }
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
                forceData.heel,
                forceData.pitch, // may not be necessary, can remove if causing errors
                forceData.roll
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
        let stops: [(threshold: Int, color: SIMD3<Double>)] = [
            (0, SIMD3(0.0, 0.0, 1.0)), // Blue
            (27, SIMD3(0.0, 1.0, 1.0)), // Cyan
            (65, SIMD3(0.0, 1.0, 0.0)), // Green
            (102, SIMD3(0.5, 1.0, 0.0)), // Lime
            (130, SIMD3(1.0, 1.0, 0.0)), // Yellow
            (167, SIMD3(1.0, 0.75, 0.0)), // Yellow-Orange
            (190, SIMD3(1.0, 0.5, 0.0)), // Orange
            (222, SIMD3(1.0, 0.25, 0.0)), // Reddish
            (250, SIMD3(1.0, 0.0, 0.0)) // Red
        ]

        // Find the two bounding stops and interpolate
        for i in 0..<stops.count - 1 {
            let (lowVal, lowColor) = stops[i]
            let (highVal, highColor) = stops[i + 1]

            if clamped <= highVal {
                let t = Double(clamped - lowVal) / Double(highVal - lowVal)
                let resultRGB = linearInterpolate(a: lowColor, b: highColor, t: t)
                return Color(red: resultRGB.x, green: resultRGB.y, blue: resultRGB.z)
            }
        }

        return Color.red // fallback
    }
    
    func linearInterpolate(a: SIMD3<Double>, b: SIMD3<Double>, t: Double) -> SIMD3<Double> {
        return a + (b - a) * t
    }
    
}
