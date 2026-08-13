//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
import Combine

/// A single characteristic of a ``BBDevice``'s discovered service.  Instances appear in ``BBDevice/services``
/// once ``BBDevice/discoverServices()`` completes. Check ``properties`` before calling an operation.
/// Calling an unsupported operation fails with an error from CoreBluetooth.
public class BBCharacteristic: NSObject, Identifiable {
    init(peripheral: CBPeripheral, characteristic: CBCharacteristic, operationQueue: BBOperationQueueProtocol?) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.operationQueue = operationQueue
    }

    let peripheral: CBPeripheral
    let characteristic: CBCharacteristic

    // MARK: - Observable properties

    /// The characteristic's current value: the result of the last successful ``read()``, or the
    /// last notification received while subscribed. `nil` by default.
    public let data = CurrentValueSubject<Data?, Never>(nil)

    /// Whether notifications are currently enabled for this characteristic. Updates automatically
    /// after ``subscribe()``/``unsubscribe()`` complete.
    public let isNotifying = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Computed properties

    /// This characteristic's Bluetooth UUID.
    public var id: BBUUID {
        get {
            return characteristic.uuid
        }
    }

    /// The operations this characteristic supports, as reported by the peripheral.
    public var properties: Set<BBCharacteristicProperty> {
        get {
            var result = Set<BBCharacteristicProperty>()
            if characteristic.properties.contains(.read) {
                result.insert(.read)
            }
            if characteristic.properties.contains(.write) {
                result.insert(.writeWithResponse)
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                result.insert(.writeWithoutResponse)
            }
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                result.insert(.notify)
            }
            return result
        }
    }

    // MARK: - Operation queue

    weak var operationQueue: BBOperationQueueProtocol?

    // Fail with an exception if the weak operation queue is not available anymore
    private func requireOperationQueue() throws -> BBOperationQueueProtocol {
        guard let operationQueue else {
            throw BBError(message: "Device is no longer available")
        }

        return operationQueue
    }

    // MARK: - Operations

    /// Reads the characteristic's current value from the peripheral, also updating ``data``.
    ///
    /// - Returns: The value read, or `nil` if the peripheral reported success with no data.
    /// - Throws: An error if the read fails, times out, or the owning device is no longer available.
    public func read() async throws -> Data? {
        let operation = BBOperationRead(peripheral: peripheral, characteristic: characteristic)
        return try await requireOperationQueue().operationEnqueue(operation)
    }

    /// Writes a value to the characteristic.
    ///
    /// - Parameters:
    ///   - data: The bytes to write.
    ///   - withResponse: When `true` (the default), waits for the peripheral to acknowledge the
    ///     write and throws on failure. When `false`, returns as soon as the write is sent, with
    ///     no delivery confirmation -- only use this if `properties` contains `.writeWithoutResponse`.
    /// - Throws: An error if the write fails, times out, or the owning device is no longer available.
    public func write(_ data: Data, withResponse: Bool = true) async throws {
        let operation = BBOperationWrite(peripheral: peripheral, characteristic: characteristic, data: data, withResponse: withResponse)
        try await requireOperationQueue().operationEnqueue(operation)
    }

    /// Subscribes to notifications/indications for this characteristic. Once subscribed, new
    /// values arrive via ``data`` as the peripheral pushes them, with no need to call ``read()``.
    ///
    /// - Throws: An error if the subscription fails, times out, or the owning device is no longer available.
    public func subscribe() async throws {
        let operation = BBOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: true)
        try await requireOperationQueue().operationEnqueue(operation)
    }

    /// Unsubscribes from notifications/indications for this characteristic.
    ///
    /// - Throws: An error if the request fails, times out, or the owning device is no longer available.
    public func unsubscribe() async throws {
        let operation = BBOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: false)
        try await requireOperationQueue().operationEnqueue(operation)
    }
}

// MARK: - Core Bluetooth protocols

extension BBCharacteristic: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }

        self.data.value = characteristic.value
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }

        self.isNotifying.value = characteristic.isNotifying
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }
    }
}
