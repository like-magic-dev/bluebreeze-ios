//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

class BBOperationRequestMTU: BBOperationImpl<Int> {
    let targetMtu: Int

    init(
        peripheral: CBPeripheral,
        targetMtu: Int,
        continuation: BBContinuation<Int>? = nil
    ) {
        self.targetMtu = targetMtu
        super.init(peripheral: peripheral, continuation: continuation)
    }
    
    override func execute(_ centralManager: CBCentralManager) {
        let mtuWithResponse = peripheral.maximumWriteValueLength(for: .withResponse)
        let mtuWithoutResponse = peripheral.maximumWriteValueLength(for: .withoutResponse)
        let mtu = min(mtuWithResponse, mtuWithoutResponse)
        
        // We add 3 to include the 3-byte header
        completeSuccess(mtu + 3)
    }
}
