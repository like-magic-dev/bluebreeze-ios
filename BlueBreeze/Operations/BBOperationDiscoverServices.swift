//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationDiscoverServices: BBOperationImpl<Void> {
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.discoverServices(nil)
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error {
            completeError(error)
            return
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error {
            completeError(error)
            return
        }
        
        // A missing service means that discovery is not complete
        if peripheral.services?.contains(where: { $0.characteristics == nil }) == true {
            return
        }
        
        completeSuccess(())
    }
}
