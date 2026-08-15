//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationConnect: BBOperation<Void> {
    override func execute(_ centralManager: CBCentralManagerProtocol) {
        centralManager.connect(peripheral)
    }

    override func centralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol) {
        completeSuccess(())
    }

    override func centralManager(_ central: CBCentralManagerProtocol, didFailToConnect peripheral: CBPeripheralProtocol, error: (any Error)?) {
        completeError(BBError(message: error?.localizedDescription ?? ""))
    }
}
