//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
@testable import BlueBreeze

/// A `CBPeripheralProtocol` mock. Records every call so tests can assert on it, and lets tests
/// simulate CoreBluetooth's async delegate callbacks synchronously via the `on...` hooks -- e.g.
/// setting `onDiscoverServices` to call back into `BBDevice.peripheral(_:didDiscoverServices:)`
/// makes `discoverServices(_:)` behave as if CoreBluetooth completed discovery immediately.
// Test-only: single-threaded within a test, and briefly handed to DispatchQueue.main.async to
// simulate an asynchronous CoreBluetooth callback (see BBDeviceTests).
final class MockCBPeripheral: CBPeripheralProtocol, @unchecked Sendable {
    init(identifier: UUID = UUID(), name: String? = nil) {
        self.identifier = identifier
        self.name = name
    }

    let identifier: UUID
    var name: String?
    var services_: [CBServiceProtocol]?

    private(set) var discoverServicesCalls: [[CBUUID]?] = []
    private(set) var discoverCharacteristicsCalls: [(characteristicUUIDs: [CBUUID]?, service: CBServiceProtocol)] = []
    private(set) var readValueCalls: [CBCharacteristicProtocol] = []
    private(set) var writeValueCalls: [(data: Data, characteristic: CBCharacteristicProtocol, type: CBCharacteristicWriteType)] = []
    private(set) var setNotifyValueCalls: [(enabled: Bool, characteristic: CBCharacteristicProtocol)] = []

    var maximumWriteValueLengthWithResponse = 20
    var maximumWriteValueLengthWithoutResponse = 20

    var onDiscoverServices: (() -> Void)?
    var onDiscoverCharacteristics: ((CBServiceProtocol) -> Void)?
    var onReadValue: ((CBCharacteristicProtocol) -> Void)?
    var onWriteValue: ((CBCharacteristicProtocol) -> Void)?
    var onSetNotifyValue: ((Bool, CBCharacteristicProtocol) -> Void)?

    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesCalls.append(serviceUUIDs)
        onDiscoverServices?()
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceProtocol) {
        discoverCharacteristicsCalls.append((characteristicUUIDs, service))
        onDiscoverCharacteristics?(service)
    }

    func readValue(for characteristic: CBCharacteristicProtocol) {
        readValueCalls.append(characteristic)
        onReadValue?(characteristic)
    }

    func writeValue(_ data: Data, for characteristic: CBCharacteristicProtocol, type: CBCharacteristicWriteType) {
        writeValueCalls.append((data, characteristic, type))
        onWriteValue?(characteristic)
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicProtocol) {
        setNotifyValueCalls.append((enabled, characteristic))
        onSetNotifyValue?(enabled, characteristic)
    }

    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        type == .withResponse ? maximumWriteValueLengthWithResponse : maximumWriteValueLengthWithoutResponse
    }
}
