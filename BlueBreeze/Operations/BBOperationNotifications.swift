//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationNotifications: BBOperationImpl<Void> {
    let characteristic: CBCharacteristic
    let enabled: Bool
    
    init(
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        enabled: Bool,
        continuation: BBContinuation<Void>? = nil
    ) {
        self.characteristic = characteristic
        self.enabled = enabled
        super.init(peripheral: peripheral, continuation: continuation)
    }
    
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if self.characteristic == characteristic {
            if let error {
                completeError(error)
                return
            }

            completeSuccess(())
        }
    }
}
