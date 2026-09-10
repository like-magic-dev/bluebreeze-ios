//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationConnect: BBOperation<Void> {
    override func execute(_ centralManager: CBCentralManagerProtocol) {
        // Short circuit operation for already connected peripherals
        guard peripheral.state != .connected else {
            completeSuccess(())
            return
        }

        centralManager.connect(peripheral)
    }

    override func cancel(_ centralManager: CBCentralManagerProtocol) {
        // Cancel the pending connection before failing
        centralManager.cancelPeripheralConnection(peripheral)
        super.cancel(centralManager)
    }

    override func centralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol) {
        completeSuccess(())
    }

    override func centralManager(_ central: CBCentralManagerProtocol, didFailToConnect peripheral: CBPeripheralProtocol, error: (any Error)?) {
        completeError(BBError(message: error?.localizedDescription ?? ""))
    }
}
