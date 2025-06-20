//
//  BluetoothManager.swift
//  GaitAnalysisApp
//
//  Created by Sarah Qiao on 2025-06-19.
//

import Foundation

class BluetoothManager: NSObject, ObservableObject {
    @Published var forceLevel: Int = 0;
    
    private var bluetoothIO: BluetoothIO!
    
    override init() {
        super.init()
        bluetoothIO = BluetoothIO(serviceUUID: "42f66074-73ac-44ba-b655-483c6f673e33", delegate: self)
    }
}

extension BluetoothManager: BluetoothIODelegate {
    func bluetoothIO(bluetoothIO: BluetoothIO, didReceiveValue value: Int8) {
        DispatchQueue.main.async {
            self.forceLevel = Int(value)
        }
    }
}
