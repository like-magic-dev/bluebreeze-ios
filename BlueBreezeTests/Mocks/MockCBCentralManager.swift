//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
@testable import BlueBreeze

/// A `CBCentralManagerProtocol` mock. Records every call so tests can assert on it, and lets
/// tests simulate CoreBluetooth's async delegate callbacks synchronously via the `on...` hooks --
/// e.g. setting `onConnect` to call back into `BBDevice.centralManager(_:didConnect:)` makes
/// `connect(_:)` behave as if CoreBluetooth completed the connection immediately.
final class MockCBCentralManager: CBCentralManagerProtocol {
    var state: CBManagerState = .poweredOn
    var authorization: CBManagerAuthorization = .allowedAlways

    private(set) var scanForPeripheralsCalls: [(serviceUUIDs: [CBUUID]?, options: [String: Any]?)] = []
    private(set) var stopScanCallCount = 0
    private(set) var connectedPeripherals: [CBPeripheralProtocol] = []
    private(set) var cancelledPeripherals: [CBPeripheralProtocol] = []

    var onConnect: ((CBPeripheralProtocol) -> Void)?
    var onCancelPeripheralConnection: ((CBPeripheralProtocol) -> Void)?

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        scanForPeripheralsCalls.append((serviceUUIDs, options))
    }

    func stopScan() {
        stopScanCallCount += 1
    }

    func connect(_ peripheral: CBPeripheralProtocol) {
        connectedPeripherals.append(peripheral)
        onConnect?(peripheral)
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol) {
        cancelledPeripherals.append(peripheral)
        onCancelPeripheralConnection?(peripheral)
    }
}
