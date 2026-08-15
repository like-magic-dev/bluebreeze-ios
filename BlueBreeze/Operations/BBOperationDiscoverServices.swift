//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationDiscoverServices: BBOperation<Void> {
    override func execute(_ centralManager: CBCentralManagerProtocol) {
        peripheral.discoverServices(nil)
    }

    override func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverServices error: (any Error)?) {
        if let error {
            completeError(error)
            return
        }

        guard let services = peripheral.services_, !services.isEmpty else {
            // Complete immediately if there are no services
            completeSuccess(())
            return
        }

        services.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    override func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverCharacteristicsFor service: CBServiceProtocol, error: (any Error)?) {
        if let error {
            completeError(error)
            return
        }

        // A missing service means that discovery is not complete
        if peripheral.services_?.contains(where: { $0.characteristics_ == nil }) == true {
            return
        }

        completeSuccess(())
    }
}
