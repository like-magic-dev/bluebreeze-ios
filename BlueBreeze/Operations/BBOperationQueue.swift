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
    init(centralManager: CBCentralManager) {
        self.centralManager = centralManager
    }

    let centralManager: CBCentralManager

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

    // MARK: - Forward CoreBluetooth delegate callbacks to the current operation

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        withOperationLock {
            operationCurrent?.centralManagerDidUpdateState(central)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        withOperationLock {
            operationCurrent?.centralManager?(central, didConnect: peripheral)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.centralManager?(central, didFailToConnect: peripheral, error: error)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        }

        operationCheck()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didDiscoverServices: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        }

        operationCheck()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        withOperationLock {
            operationCurrent?.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
        }

        operationCheck()
    }
}
