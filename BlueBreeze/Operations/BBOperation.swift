//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// Async continuation object that returns a result or an error

typealias BBContinuation<RESULT> = CheckedContinuation<RESULT, Error>

/// Operation protocol

protocol BBOperationProtocol: CBCentralManagerDelegate, CBPeripheralDelegate {
    associatedtype RESULT

    // MARK: - Peripheral associated with this operation

    var peripheral: CBPeripheral { get }

    // MARK: - Object that handles the async result

    var continuation: BBContinuation<RESULT>? { get set }

    // MARK: - Execute the operation

    func execute(_ centralManager: CBCentralManager)

    // MARK: - Cancel the operation

    func cancel()

    // MARK: - Time out

    var timeOut: TimeInterval { get }
}

/// Operation protocol extension that manages completion callbacks

extension BBOperationProtocol {
    // MARK: - Complete the operation successfully with a result

    internal func completeSuccess(_ result: RESULT) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    // MARK: - Complete the operation with an error

    internal func completeError(_ error: Error?) {
        continuation?.resume(throwing: error ?? BBError.unknown)
        continuation = nil
    }

    // MARK: - Check if the operation is completed

    var isCompleted: Bool {
        get {
            return continuation == nil
        }
    }
}

/// This class implements the basic functionalities of an operation, it is useful to avoid code duplication
/// in all other specialised operations, in particular some compulsory CoreBluetooth callbacks
/// and the initialisation of peripheral and continuation

class BBOperation<T>: NSObject, BBOperationProtocol {
    typealias RESULT = T

    init(
        peripheral: CBPeripheral,
        continuation: BBContinuation<T>? = nil
    ) {
        self.peripheral = peripheral
        self.continuation = continuation
    }

    let peripheral: CBPeripheral
    var continuation: BBContinuation<T>?

    // MARK: - Execute the operation

    func execute(_ centralManager: CBCentralManager) {
        fatalError("Unimplemented error")
    }

    // MARK: - Cancel the operation

    func cancel() {
        completeError(BBError(message: "Operation cancelled"))
    }

    // MARK: - Default time out

    var timeOut: TimeInterval {
        return 5
    }

    // MARK: Central manager and peripheral callbacks

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            completeError(nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) { }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) { }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        completeError(error)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        completeError(error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) { }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) { }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) { }
}
