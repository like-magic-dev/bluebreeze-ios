//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
import Combine

/// A single BLE peripheral discovered by a ``BBManager`` scan.
///
/// `BBDevice` instances are created and owned by `BBManager` -- you never construct one
/// yourself, you get one from ``BBManager/devices`` or ``BBScanResult/device``. Each instance is
/// stable for the lifetime of the app: the same `BBDevice` is reused across repeated
/// discoveries, connects, and disconnects of the same physical peripheral.
///
/// All BLE operations (``connect()``, ``disconnect()``, ``discoverServices()``,
/// ``negotiateMTU()``, and the read/write/subscribe methods on ``BBCharacteristic``) are queued
/// and executed one at a time per device, in call order, each with a 5 second timeout. You don't
/// need to serialize calls yourself -- just `await` them.
///
/// Typical flow: connect, discover services, then read/write/subscribe to the characteristics
/// that appear in ``services``.
/// ```swift
/// try await device.connect()
/// try await device.discoverServices()
///
/// for (_, characteristics) in device.services.value {
///     for characteristic in characteristics where characteristic.properties.contains(.read) {
///         let data = try await characteristic.read()
///     }
/// }
/// ```
public class BBDevice: NSObject, BBOperationQueue {
    init(
        centralManager: CBCentralManager,
        peripheral: CBPeripheral
    ) {
        self.centralManager = centralManager
        self.peripheral = peripheral
    }

    let centralManager: CBCentralManager
    let peripheral: CBPeripheral

    /// The system-assigned identifier for this peripheral. Stable across app launches, but not
    /// guaranteed to be the same across different devices/installations for the same peripheral.
    public var id: UUID {
        get {
            return peripheral.identifier
        }
    }

    /// The peripheral's name, if it has advertised or reported one. May be `nil`, and may change
    /// (e.g. once connected, some peripherals report a more specific name than they advertised).
    public var name: String? {
        get {
            return peripheral.name
        }
    }

    /// Services and characteristics discovered so far, keyed by service UUID.
    ///
    /// A service key appears here as soon as it's discovered (with an empty characteristics
    /// array), and its characteristics populate once ``discoverServices()`` completes. Empty
    /// until ``discoverServices()`` has been called and awaited.
    public let services = CurrentValueSubject<[BBUUID: [BBCharacteristic]], Never>([:])

    // MARK: - Connection status

    /// The device's current connection state. Updates automatically on connect, disconnect, and
    /// unexpected link loss -- you don't need to poll it after calling ``connect()``/``disconnect()``.
    public let connectionStatus = CurrentValueSubject<BBDeviceConnectionStatus, Never>(.disconnected)

    // MARK: - MTU

    /// The negotiated ATT MTU (Maximum Transmission Unit) in bytes, i.e. the largest amount of
    /// data that can be sent in a single read/write. Defaults to the BLE minimum of 23 until
    /// ``negotiateMTU()`` is called and awaited.
    public let mtu = CurrentValueSubject<Int, Never>(Int.defaultMtu)

    // MARK: - Operations

    /// Connects to the peripheral. Updates ``connectionStatus`` to `.connected` on success.
    ///
    /// - Throws: An error if the connection attempt fails or times out.
    public func connect() async throws {
        try await operationEnqueue(BBOperationConnect(peripheral: peripheral))
        self.connectionStatus.value = .connected
    }

    /// Disconnects from the peripheral. Updates ``connectionStatus`` to `.disconnected` on success.
    ///
    /// - Throws: An error if the disconnect attempt fails or times out.
    public func disconnect() async throws {
        try await operationEnqueue(BBOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.value = .disconnected
    }

    /// Discovers all of the peripheral's services and their characteristics, populating
    /// ``services``. Requires an active connection.
    ///
    /// - Throws: An error if discovery fails or times out.
    public func discoverServices() async throws {
        try await operationEnqueue(BBOperationDiscoverServices(peripheral: peripheral))
    }

    /// Reads back the ATT MTU that CoreBluetooth negotiated with the peripheral, updating ``mtu``.
    ///
    /// iOS negotiates the MTU automatically as part of connecting; there is no API to request a
    /// specific value, so this only reads back the result -- it does not (and cannot) influence
    /// what gets negotiated.
    ///
    /// - Throws: An error if the underlying read fails.
    public func negotiateMTU() async throws {
        let mtu = try await operationEnqueue(BBOperationNegotiateMTU(peripheral: peripheral))
        self.mtu.value = mtu
    }

    // MARK: - Operation queue

    var operationCurrent: (any BBOperation)?
    var operationQueue: [any BBOperation] = []
    var operationLock = NSLock()

    // Runs a function atomically under operationLock
    private func withOperationLock<T>(_ body: () -> T) -> T {
        operationLock.lock()
        defer { operationLock.unlock() }
        return body()
    }

    func operationEnqueue<RESULT, OP: BBOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT {
        return try await withCheckedThrowingContinuation { continuation in
            operation.continuation = continuation

            withOperationLock {
                operationQueue.append(operation)
            }

            operationCheck()
        }
    }

    private func operationCheck() {
        let nextOperation: (any BBOperation)? = withOperationLock {
            if let operationCurrent, !operationCurrent.isCompleted {
                return nil
            }

            operationCurrent = operationQueue.popFirst()
            return operationCurrent
        }

        guard let nextOperation else {
            return
        }

        nextOperation.execute(self.centralManager)

        // The operation completed synchronously
        guard !nextOperation.isCompleted else {
            operationCheck()
            return
        }

        // The operation is still running, set a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + nextOperation.timeOut) { [weak self] in
            guard let self else { return }

            // If not already completed, cancel the operation
            let wasAlreadyCompleted = self.withOperationLock { () -> Bool in
                let alreadyCompleted = nextOperation.isCompleted
                if !alreadyCompleted {
                    nextOperation.cancel()
                }
                return alreadyCompleted
            }

            // The operation timed out, so proceed with the next queued operation
            if !wasAlreadyCompleted {
                self.operationCheck()
            }
        }
    }
}

// MARK: - CoreBluetooth delegate plumbing
//
// The methods below are `public` only because CBCentralManagerDelegate/CBPeripheralDelegate
// require it; they are called by BBManager as it forwards CoreBluetooth callbacks for this
// device's peripheral, not meant to be called directly.

extension BBDevice: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state != .poweredOn) {
            self.services.value = [:]
            self.connectionStatus.value = .disconnected
        }

        withOperationLock {
            operationCurrent?.centralManagerDidUpdateState(central)
        }

        operationCheck()
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        withOperationLock {
            operationCurrent?.centralManager?(central, didConnect: peripheral)
        }

        operationCheck()
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected

        withOperationLock {
            operationCurrent?.centralManager?(central, didFailToConnect: peripheral, error: error)
        }

        operationCheck()
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected

        withOperationLock {
            operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        }

        operationCheck()
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected

        withOperationLock {
            operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        }

        operationCheck()
    }
}

extension BBDevice: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        peripheral.services?.forEach({ service in
            if self.services.value[service.uuid] == nil {
                var services = self.services.value
                services[service.uuid] = []
                self.services.value = services
            }
        })

        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didDiscoverServices: error)
        }

        operationCheck()
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        var characteristics = self.services.value[service.uuid] ?? []

        service.characteristics?.forEach({ characteristic in
            if !characteristics.contains(where: { $0.id == characteristic.uuid }) {
                characteristics.append(
                    BBCharacteristic(
                        peripheral: peripheral,
                        characteristic: characteristic,
                        operationQueue: self
                    )
                )
            }
        })

        var services = self.services.value
        services[service.uuid] = characteristics
        self.services.value = services

        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        }

        operationCheck()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)

        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        }

        operationCheck()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        }

        operationCheck()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)

        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }

        operationCheck()
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)

        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        }

        operationCheck()
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        if let characteristic = descriptor.characteristic {
            getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
        }

        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
        }

        operationCheck()
    }
}

extension BBDevice: Identifiable { }

extension BBDevice {
    func getCharacteristicWithUUID(_ uuid: CBUUID) -> BBCharacteristic? {
        for characteristics in services.value.values {
            for characteristic in characteristics {
                if characteristic.id == uuid {
                    return characteristic
                }
            }
        }

        return nil
    }
}

extension Int {
    static var defaultMtu: Int {
        get {
            return 23
        }
    }
}
