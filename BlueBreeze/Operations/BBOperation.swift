//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// Async continuation object that returns a result or an error

typealias BBContinuation<RESULT> = CheckedContinuation<RESULT, Error>

/// Operation protocol

protocol BBOperationProtocol: AnyObject {
    associatedtype RESULT

    // MARK: - Peripheral associated with this operation

    var peripheral: CBPeripheralProtocol { get }

    // MARK: - Object that handles the async result

    var continuation: BBContinuation<RESULT>? { get set }

    // MARK: - Execute the operation

    func execute(_ centralManager: CBCentralManagerProtocol)

    // MARK: - Cancel the operation

    func cancel()

    // MARK: - Time out

    var timeOut: TimeInterval { get }

    // MARK: - Central manager and peripheral callbacks, mirroring CBCentralManagerDelegate/CBPeripheralDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManagerProtocol)
    func centralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol)
    func centralManager(_ central: CBCentralManagerProtocol, didFailToConnect peripheral: CBPeripheralProtocol, error: (any Error)?)
    func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, error: (any Error)?)
    func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?)

    func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverServices error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverCharacteristicsFor service: CBServiceProtocol, error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor characteristic: CBCharacteristicProtocol, error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor descriptor: CBDescriptorProtocol, error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateNotificationStateFor characteristic: CBCharacteristicProtocol, error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor characteristic: CBCharacteristicProtocol, error: (any Error)?)
    func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor descriptor: CBDescriptorProtocol, error: (any Error)?)
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

class BBOperation<T>: BBOperationProtocol {
    typealias RESULT = T

    init(
        peripheral: CBPeripheralProtocol,
        continuation: BBContinuation<T>? = nil
    ) {
        self.peripheral = peripheral
        self.continuation = continuation
    }

    let peripheral: CBPeripheralProtocol
    var continuation: BBContinuation<T>?

    // MARK: - Execute the operation

    func execute(_ centralManager: CBCentralManagerProtocol) {
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

    func centralManagerDidUpdateState(_ central: CBCentralManagerProtocol) {
        if central.state != .poweredOn {
            completeError(nil)
        }
    }

    func centralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol) { }
    func centralManager(_ central: CBCentralManagerProtocol, didFailToConnect peripheral: CBPeripheralProtocol, error: Error?) { }

    func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, error: Error?) {
        completeError(error)
    }

    func centralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        completeError(error)
    }

    func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverServices error: Error?) { }
    func peripheral(_ peripheral: CBPeripheralProtocol, didDiscoverCharacteristicsFor service: CBServiceProtocol, error: Error?) { }

    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor characteristic: CBCharacteristicProtocol, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateValueFor descriptor: CBDescriptorProtocol, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheralProtocol, didUpdateNotificationStateFor characteristic: CBCharacteristicProtocol, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor characteristic: CBCharacteristicProtocol, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheralProtocol, didWriteValueFor descriptor: CBDescriptorProtocol, error: Error?) { }
}
