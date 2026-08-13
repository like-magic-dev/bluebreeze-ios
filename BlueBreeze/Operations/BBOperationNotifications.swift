//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationNotifications: BBOperation<Void> {
    let characteristic: CBCharacteristicProtocol
    let enabled: Bool

    init(
        peripheral: CBPeripheralProtocol,
        characteristic: CBCharacteristicProtocol,
        enabled: Bool,
        continuation: BBContinuation<Void>? = nil
    ) {
        self.characteristic = characteristic
        self.enabled = enabled
        super.init(peripheral: peripheral, continuation: continuation)
    }

    override func execute(_ centralManager: CBCentralManagerProtocol) {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }

    override func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateNotificationStateFor characteristic: CBCharacteristicProtocol, error: (any Error)?) {
        if self.characteristic.uuid == characteristic.uuid {
            if let error {
                completeError(error)
                return
            }

            completeSuccess(())
        }
    }
}
