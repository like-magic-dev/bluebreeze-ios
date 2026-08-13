//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
import Combine

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

    public var id: UUID {
        get {
            return peripheral.identifier
        }
    }

    public var name: String? {
        get {
            return peripheral.name
        }
    }

    public let services = CurrentValueSubject<[BBUUID: [BBCharacteristic]], Never>([:])

    // MARK: - Connection status

    public let connectionStatus = CurrentValueSubject<BBDeviceConnectionStatus, Never>(.disconnected)

    // MARK: - MTU

    public let mtu = CurrentValueSubject<Int, Never>(Int.defaultMtu)

    // MARK: - Operations

    public func connect() async throws {
        try await operationEnqueue(BBOperationConnect(peripheral: peripheral))
        self.connectionStatus.value = .connected
    }

    public func disconnect() async throws {
        try await operationEnqueue(BBOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.value = .disconnected
    }

    public func discoverServices() async throws {
        try await operationEnqueue(BBOperationDiscoverServices(peripheral: peripheral))
    }

    public func requestMTU(_ mtu: Int) async throws {
        let mtu = try await operationEnqueue(BBOperationRequestMTU(peripheral: peripheral, targetMtu: 512))
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

        self.operationCheck()
    }
}

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
