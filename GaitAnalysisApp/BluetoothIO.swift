//
//  BluetoothIO.swift
//  GaitAnalysisApp
//
//  Created by Sarah Qiao on 2025-06-19.
//

import CoreBluetooth

protocol BluetoothIODelegate: AnyObject {
    func bluetoothIO(bluetoothIO: BluetoothIO, didReceiveValue value: Int8)
}

//Global BLE device manager
class BluetoothIO: NSObject {
    let serviceUUID: String
    weak var delegate: BluetoothIODelegate?
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetService: CBService?
    var writableCharacteristic: CBCharacteristic?
    
    init(serviceUUID: String, delegate: BluetoothIODelegate?) {
        self.serviceUUID = serviceUUID
        self.delegate = delegate
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

//Check discovery and connection
extension BluetoothIO: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        if let name = peripheral.name {
            print("Connected to \(name)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral
        if let name = peripheral.name {
            print("Discovered \(name)")
            if peripheral.name == "BLE_DEVICE" {
                if let connectedPeripheral = connectedPeripheral {
                    connectedPeripheral.delegate = self
                    centralManager.connect(connectedPeripheral, options: nil)
                }
            }
            centralManager.stopScan()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
}

extension BluetoothIO: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        targetService = services.first
        if let service = services.first {
            targetService = service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
//    Discover characteristics (single value and any number of descriptors for that value)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
            }
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, let delegate = delegate else {
            return
        }
        delegate.bluetoothIO(bluetoothIO: self, didReceiveValue: data.withUnsafeBytes({ $0.load(as: Int8.self) }))
    }
}
