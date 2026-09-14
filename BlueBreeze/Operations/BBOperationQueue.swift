//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// Protocol to enqueue an operation and transform it into an async-awaitable result

protocol BBOperationQueueProtocol: AnyObject {
    // MARK: - Enqueue an operation -- allows awaiting for the result asynchronously
    func operationEnqueue<RESULT, OP: BBOperationProtocol>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT
}

/// Runs a device's ``BBOperation`` queue one at a time, in call order, each with a timeout.
///
/// Owns the queue and the currently-executing operation. CoreBluetooth delegate callbacks aren't
/// received here directly. The owning delegate forwards them in via the methods below, which route
/// them to the current operation and then check whether the next queued operation can start.

class BBOperationQueue: BBOperationQueueProtocol {
    init(centralManager: CBCentralManagerProtocol, queue: DispatchQueue) {
        self.centralManager = centralManager
        self.queue = queue
    }

    private let centralManager: CBCentralManagerProtocol
    private let queue: DispatchQueue

    private var operationCurrent: (any BBOperationProtocol)?
    private var operationQueue: [any BBOperationProtocol] = []
    private var operationLock = NSLock()

    // Runs a function atomically under operationLock
    private func withOperationLock<T>(_ body: () -> T) -> T {
        operationLock.lock()
        defer { operationLock.unlock() }
        return body()
    }

    func operationEnqueue<RESULT, OP: BBOperationProtocol>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT {
        return try await withCheckedThrowingContinuation { continuation in
            operation.continuation = continuation

            withOperationLock {
                operationQueue.append(operation)
            }

            operationCheck()
        }
    }

    private func operationCheck() {
        let nextOperation: (any BBOperationProtocol)? = withOperationLock {
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
        let isCompleted = withOperationLock { nextOperation.isCompleted }
        guard !isCompleted else {
            operationCheck()
            return
        }

        // The operation is still running, set a timeout
        self.queue.asyncAfter(deadline: .now() + nextOperation.timeOut) { [weak self] in
            guard let self else { return }

            // If not already completed, cancel the operation
            let wasAlreadyCompleted = self.withOperationLock { () -> Bool in
                let alreadyCompleted = nextOperation.isCompleted
                if !alreadyCompleted {
                    nextOperation.cancel(self.centralManager)
                }
                return alreadyCompleted
            }

            // The operation timed out, so proceed with the next queued operation
            if !wasAlreadyCompleted {
                self.operationCheck()
            }
        }
    }

    // MARK: - Fast-cancel paths, for when waiting out a stuck operation isn't acceptable

    /// Cancels the executing operation and discards every queued operation
    func cancelAll() {
        let (current, queued) = withOperationLock { () -> ((any BBOperationProtocol)?, [any BBOperationProtocol]) in
            let current = operationCurrent
            let queued = operationQueue
            operationCurrent = nil
            operationQueue = []
            return (current, queued)
        }

        if let current, !current.isCompleted {
            current.cancel(centralManager)
        }

        for operation in queued where !operation.isCompleted {
            operation.cancel(centralManager)
        }
    }

    /// Discards every operation still waiting in the queue
    func cancelQueued() {
        let queued = withOperationLock { () -> [any BBOperationProtocol] in
            let queued = operationQueue
            operationQueue = []
            return queued
        }

        for operation in queued where !operation.isCompleted {
            operation.cancel(centralManager)
        }
    }

    // MARK: - Forward CoreBluetooth delegate callbacks to the current operation

    func centralManagerDidUpdateState(_ central: CBCentralManagerProtocol) {
        withOperationLock {
            operationCurrent?.centralManagerDidUpdateState(central)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol) {
        withOperationLock {
            operationCurrent?.centralManager(central, didConnect: peripheral)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManagerProtocol, didFailToConnect peripheral: CBPeripheralProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.centralManager(central, didFailToConnect: peripheral, error: error)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.centralManager(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverServices error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didDiscoverServices: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverCharacteristicsFor service: CBServiceProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor characteristic: CBCharacteristicProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor descriptor: CBDescriptorProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didUpdateValueFor: descriptor, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateNotificationStateFor characteristic: CBCharacteristicProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor characteristic: CBCharacteristicProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor descriptor: CBDescriptorProtocol, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
        }

        operationCheck()
    }
}

extension Array where Element: Any {
    mutating func popFirst() -> Self.Element? {
        guard let first = first else {
            return nil
        }

        remove(at: 0)
        return first
    }
}
