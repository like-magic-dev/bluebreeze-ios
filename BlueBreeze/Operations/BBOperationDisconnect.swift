//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationDisconnect: BBOperation<Void> {
    override func execute(_ centralManager: CBCentralManagerProtocol) {
        centralManager.cancelPeripheralConnection(peripheral)
    }

    override func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, error: (any Error)?) {
        if let error {
            completeError(error)
        } else {
            completeSuccess(())
        }
    }

    override func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        if let error {
            completeError(error)
            return
        }

        completeSuccess(())
    }
}
