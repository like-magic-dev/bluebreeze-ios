import CoreBluetooth
import Combine

public class BBCharacteristic: NSObject, Identifiable {
    init(peripheral: CBPeripheral, characteristic: CBCharacteristic, operationQueue: BBOperationQueue?) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.operationQueue = operationQueue
    }
    
    let peripheral: CBPeripheral
    let characteristic: CBCharacteristic
    
    weak var operationQueue: BBOperationQueue?
    
    // MARK: - Observable properties
    
    public let data = CurrentValueSubject<Data, Never>(Data())
    public let isNotifying = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - Computed properties
    
    public var id: BBUUID {
        get {
            return characteristic.uuid
        }
    }
    
    public var canRead: Bool {
        get {
            return characteristic.properties.contains(.read)
        }
    }
    
    public var canWrite: Bool {
        get {
            return characteristic.properties.contains(.write)
        }
    }
    
    public var canWriteWithoutResponse: Bool {
        get {
            return characteristic.properties.contains(.writeWithoutResponse)
        }
    }
    
    public var canNotify: Bool {
        get {
            return characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
        }
    }
    
    // MARK: - Operations
    
    public func read() {
        Task {
            let operation = BBOperationRead(peripheral: peripheral, characteristic: characteristic)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
    
    public func write(_ data: Data, withResponse: Bool = true) {
        Task {
            let operation = BBOperationRead(peripheral: peripheral, characteristic: characteristic)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
    
    public func subscribe() {
        Task {
            let operation = BBOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: true)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
    
    public func unsubscribe() {
        Task {
            let operation = BBOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: false)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
}

// MARK: - Core Bluetooth protocols

extension BBCharacteristic: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }
        
        if let value = characteristic.value {
            self.data.value = value
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }
        
        self.isNotifying.value = characteristic.isNotifying
    }
}
