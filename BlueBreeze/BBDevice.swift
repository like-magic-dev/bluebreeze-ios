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
public class BBDevice: NSObject {
    init(
        centralManager: CBCentralManager,
        peripheral: CBPeripheral
    ) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        self.operationQueueManager = BBOperationQueue(centralManager: centralManager)
    }

    let centralManager: CBCentralManager
    let peripheral: CBPeripheral
    let operationQueueManager: BBOperationQueue

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
        try await operationQueueManager.operationEnqueue(BBOperationConnect(peripheral: peripheral))
        self.connectionStatus.value = .connected
    }

    /// Disconnects from the peripheral. Updates ``connectionStatus`` to `.disconnected` on success.
    ///
    /// - Throws: An error if the disconnect attempt fails or times out.
    public func disconnect() async throws {
        try await operationQueueManager.operationEnqueue(BBOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.value = .disconnected
    }

    /// Discovers all of the peripheral's services and their characteristics, populating
    /// ``services``. Requires an active connection.
    ///
    /// - Throws: An error if discovery fails or times out.
    public func discoverServices() async throws {
        try await operationQueueManager.operationEnqueue(BBOperationDiscoverServices(peripheral: peripheral))
    }

    /// Reads back the ATT MTU that CoreBluetooth negotiated with the peripheral, updating ``mtu``.
    ///
    /// iOS negotiates the MTU automatically as part of connecting; there is no API to request a
    /// specific value, so this only reads back the result -- it does not (and cannot) influence
    /// what gets negotiated.
    ///
    /// - Throws: An error if the underlying read fails.
    public func negotiateMTU() async throws {
        let mtu = try await operationQueueManager.operationEnqueue(BBOperationNegotiateMTU(peripheral: peripheral))
        self.mtu.value = mtu
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

        operationQueueManager.centralManagerDidUpdateState(central)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        operationQueueManager.centralManager(central, didConnect: peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected

        operationQueueManager.centralManager(central, didFailToConnect: peripheral, error: error)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected

        operationQueueManager.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected

        operationQueueManager.centralManager(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
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

        operationQueueManager.peripheral(peripheral, didDiscoverServices: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        var characteristics = self.services.value[service.uuid] ?? []

        service.characteristics?.forEach({ characteristic in
            if !characteristics.contains(where: { $0.id == characteristic.uuid }) {
                characteristics.append(
                    BBCharacteristic(
                        peripheral: peripheral,
                        characteristic: characteristic,
                        operationQueue: operationQueueManager
                    )
                )
            }
        })

        var services = self.services.value
        services[service.uuid] = characteristics
        self.services.value = services

        operationQueueManager.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)

        operationQueueManager.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        operationQueueManager.peripheral(peripheral, didUpdateValueFor: descriptor, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)

        operationQueueManager.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)

        operationQueueManager.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        if let characteristic = descriptor.characteristic {
            getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
        }

        operationQueueManager.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
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
