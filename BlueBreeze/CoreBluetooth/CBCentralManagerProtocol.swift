//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The subset of `CBCentralManager` that BlueBreeze depends on.
/// Makes BlueBreeze public classes independent of CoreBluetooth data structures. 

protocol CBCentralManagerProtocol: AnyObject {
    var state: CBManagerState { get }
    var authorization: CBManagerAuthorization { get }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()

    func connect(_ peripheral: CBPeripheralProtocol)
    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol)
}

extension CBCentralManager: CBCentralManagerProtocol {
    func connect(_ peripheral: CBPeripheralProtocol) {
        guard let peripheral = peripheral as? CBPeripheral else { return }
        connect(peripheral, options: nil)
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol) {
        guard let peripheral = peripheral as? CBPeripheral else { return }
        cancelPeripheralConnection(peripheral)
    }
}
