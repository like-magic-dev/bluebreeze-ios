//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The subset of `CBPeripheral` that BlueBreeze depends on.
/// Makes BlueBreeze public classes independent of CoreBluetooth data structures.

protocol CBPeripheralProtocol: AnyObject {
    var identifier: UUID { get }
    var name: String? { get }
    var services_: [CBServiceProtocol]? { get }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceProtocol)
    func readValue(for characteristic: CBCharacteristicProtocol)
    func writeValue(_ data: Data, for characteristic: CBCharacteristicProtocol, type: CBCharacteristicWriteType)
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicProtocol)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
}

extension CBPeripheral: CBPeripheralProtocol {
    var services_: [CBServiceProtocol]? {
        services
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceProtocol) {
        guard let service = service as? CBService else { return }
        discoverCharacteristics(characteristicUUIDs, for: service)
    }

    func readValue(for characteristic: CBCharacteristicProtocol) {
        guard let characteristic = characteristic as? CBCharacteristic else { return }
        readValue(for: characteristic)
    }

    func writeValue(_ data: Data, for characteristic: CBCharacteristicProtocol, type: CBCharacteristicWriteType) {
        guard let characteristic = characteristic as? CBCharacteristic else { return }
        writeValue(data, for: characteristic, type: type)
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicProtocol) {
        guard let characteristic = characteristic as? CBCharacteristic else { return }
        setNotifyValue(enabled, for: characteristic)
    }
}
