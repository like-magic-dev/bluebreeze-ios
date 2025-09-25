//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationWrite: BBOperationImpl<Void> {
    let characteristic: CBCharacteristic
    let data: Data
    let withResponse: Bool

    init(
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        data: Data,
        withResponse: Bool,
        continuation: BBContinuation<Void>? = nil
    ) {
        self.characteristic = characteristic
        self.data = data
        self.withResponse = withResponse
        super.init(peripheral: peripheral, continuation: continuation)
    }
    
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.writeValue(data, for: characteristic, type: withResponse ? .withResponse : .withoutResponse)
        
        if !withResponse {
            completeSuccess(())
        }
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if self.characteristic == characteristic {
            if let error {
                completeError(error)
                return
            }

            completeSuccess(())
        }
    }
}
