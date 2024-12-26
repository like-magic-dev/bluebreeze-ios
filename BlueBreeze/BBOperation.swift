import CoreBluetooth

/// Async continuation object that returns a result or an error

typealias BBContinuation<RESULT> = CheckedContinuation<RESULT, Error>

/// Operation protocol

protocol BBOperation: CBCentralManagerDelegate, CBPeripheralDelegate {
    associatedtype RESULT

    // MARK: - Peripheral associated with this operation
    
    var peripheral: CBPeripheral { get }
    
    // MARK: - Object that handles the async result
    
    var continuation: BBContinuation<RESULT>? { get set }
    
    // MARK: - Execute the operation
    
    func execute(_ centralManager: CBCentralManager)
    
    // MARK: - Cancel the operation
    
    func cancel()
}

/// Operation protocol extension that manages completion callbacks

extension BBOperation {
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
