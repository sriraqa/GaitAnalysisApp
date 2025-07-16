//
//  BluetoothManager.swift
//  GaitAnalysisApp
//
//  Created by Sarah Qiao on 2025-06-19.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let advertisementServiceUUIDs: [String]?
    let peripheral: CBPeripheral
}

struct ForceData: Decodable, Equatable {
    let heel: String
    let big_toe: String
    let arch: String
    let ball: String
    let sole: String
    let pitch: String
    let roll: String
}

// BLEManager class conforms to observable object for SwiftUI, CBCentralManagerDelegate and CBPeripheralDelegate for managing BLE connections.
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // Constants specific to the ESP32 BLE service and characteristic UUIDs.
    enum ESP32Constants {
        static let serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        static let characteristicUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    }

    // Central manager to handle BLE operations.
    var centralManager: CBCentralManager!
    // Reference to the connected ESP32 peripheral.
    var esp32Peripheral: CBPeripheral?
    // Reference to the characteristic through which communication happens.
    var esp32Characteristic: CBCharacteristic?

    @Published var peripherals: [Peripheral] = []
    @Published var isConnected = false // Indicates if the app is connected to a peripheral.
    @Published var forceLevel: ForceData = ForceData(heel: "0", big_toe: "0", arch: "0", ball: "0", sole: "0", pitch: "0", roll: "0") // numbers that indicates the read values

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Function to send a string value to the ESP32.
    func sendTextValue(_ text: String) {
        let data = Data(text.utf8)
        if let myCharacteristic = esp32Characteristic {
            esp32Peripheral?.writeValue(data, for: myCharacteristic, type: .withResponse)
        }
    }

    // Function to initiate a connection to a chosen peripheral.
    func connectPeripheral(peripheral: Peripheral) {
        guard let foundPeripheral = peripherals.first(where: { $0.id == peripheral.id })?.peripheral else { return }
        esp32Peripheral = foundPeripheral
        esp32Peripheral?.delegate = self
        centralManager.connect(foundPeripheral, options: nil)
    }

    // Function to disconnect from the current peripheral.
    func disconnectFromPeripheral() {
        if let peripheral = esp32Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func refreshDevices() {
        if centralManager.state == .poweredOn {
            peripherals.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Started scanning")
        } else {
            print("Bluetooth is not powered on")
        }
    }

    // MARK: - CBCentralManagerDelegate Methods

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        refreshDevices()
    }

    // Called when a peripheral is discovered during scanning.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name?.contains("ESP32") ?? false {
            let adsServiceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.compactMap({ data in
                data.uuidString
            })

            let newPeripheral = Peripheral(id: peripheral.identifier,
                                           name: peripheral.name ?? "Unknown",
                                           rssi: RSSI.intValue,
                                           advertisementServiceUUIDs: adsServiceUUIDs,
                                           peripheral: peripheral)
            if !peripherals.contains(where: { $0.id == newPeripheral.id }) {
                peripherals.append(newPeripheral)
            }
        }
    }

    // Called when a connection is successfully established with a peripheral.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        print("Connected to \(peripheral.name ?? "Unknown")")
        esp32Peripheral?.discoverServices([CBUUID(string: ESP32Constants.serviceUUID)])
        centralManager.stopScan()
    }

    // Called when the peripheral is disconnected.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        esp32Peripheral = nil
        esp32Characteristic = nil
        peripherals.removeAll()
        refreshDevices()
    }

    // MARK: - CBPeripheralDelegate Methods

    // Called when services of a peripheral are discovered.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                // Discover characteristics for the service with the specified UUID
                print("Discovered service: \(service.uuid)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    // Called when characteristics for a service are discovered.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.notify) {
                    esp32Characteristic = characteristic
                    print("Properties: \(characteristic.properties)")

                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    // Called when the value of a characteristic is updated.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }

        if characteristic == esp32Characteristic {
            if let data = characteristic.value {
                if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON String: \(jsonString)")
                    }
                print("Force Levels: \(data)")
                do {
                    let decoded = try JSONDecoder().decode(ForceData.self, from: data)
                    forceLevel = decoded
                    print("Force Levels: \(forceLevel)")
                } catch {
                    print(error)
                }
            }
        }
    }

    // Called when a value is successfully written to a characteristic.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error in sending data: \(error)")
            return
        }
        print("Data has been successfully sent and processed.")
    }
}
