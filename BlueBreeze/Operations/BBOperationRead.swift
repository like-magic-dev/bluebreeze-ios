//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationRead: BBOperation<Data?> {
    let characteristic: CBCharacteristicProtocol

    init(
        peripheral: CBPeripheralProtocol,
        characteristic: CBCharacteristicProtocol,
        continuation: BBContinuation<Data?>? = nil
    ) {
        self.characteristic = characteristic
        super.init(peripheral: peripheral, continuation: continuation)
    }

    override func execute(_ centralManager: CBCentralManagerProtocol) {
        peripheral.readValue(for: characteristic)
    }

    override func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor characteristic: CBCharacteristicProtocol, error: Error?) {
        if self.characteristic.uuid == characteristic.uuid {
            if let error {
                completeError(error)
                return
            }

            completeSuccess(characteristic.value)
        }
    }
}
