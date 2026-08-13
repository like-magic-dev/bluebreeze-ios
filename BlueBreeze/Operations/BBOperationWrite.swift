//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationWrite: BBOperation<Void> {
    let characteristic: CBCharacteristicProtocol
    let data: Data
    let withResponse: Bool

    init(
        peripheral: CBPeripheralProtocol,
        characteristic: CBCharacteristicProtocol,
        data: Data,
        withResponse: Bool,
        continuation: BBContinuation<Void>? = nil
    ) {
        self.characteristic = characteristic
        self.data = data
        self.withResponse = withResponse
        super.init(peripheral: peripheral, continuation: continuation)
    }

    override func execute(_ centralManager: CBCentralManagerProtocol) {
        peripheral.writeValue(data, for: characteristic, type: withResponse ? .withResponse : .withoutResponse)

        if !withResponse {
            completeSuccess(())
        }
    }

    override func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor characteristic: CBCharacteristicProtocol, error: (any Error)?) {
        if self.characteristic.uuid == characteristic.uuid {
            if let error {
                completeError(error)
                return
            }

            completeSuccess(())
        }
    }
}
