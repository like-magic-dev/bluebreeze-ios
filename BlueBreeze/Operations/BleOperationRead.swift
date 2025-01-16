//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationRead: BBOperationImpl<Data?> {
    let characteristic: CBCharacteristic

    init(
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        continuation: BBContinuation<Data?>? = nil
    ) {
        self.characteristic = characteristic
        super.init(peripheral: peripheral, continuation: continuation)
    }
    
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.readValue(for: characteristic)
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.characteristic == characteristic {
            if let error = error {
                completeError(error)
                return
            }
            
            completeSuccess(characteristic.value)
        }
    }
}
