import CoreBluetooth
import Combine

class BleCharacteristic: NSObject, Identifiable {
    init(peripheral: CBPeripheral, characteristic: CBCharacteristic, operationQueue: BleOperationQueue?) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.operationQueue = operationQueue
    }
    
    let peripheral: CBPeripheral
    let characteristic: CBCharacteristic
    
    weak var operationQueue: BleOperationQueue?
    
    // MARK: - Observable properties
    
    let data = CurrentValueSubject<Data, Never>(Data())
    let isNotifying = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - Computed properties
    
    var id: CBUUID {
        get {
            return characteristic.uuid
        }
    }
    
    var canRead: Bool {
        get {
            return characteristic.properties.contains(.read)
        }
    }
    
    var canWrite: Bool {
        get {
            return characteristic.properties.contains(.write)
        }
    }
    
    var canWriteWithoutResponse: Bool {
        get {
            return characteristic.properties.contains(.writeWithoutResponse)
        }
    }
    
    var canNotify: Bool {
        get {
            return characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
        }
    }
    
    // MARK: - Operations
    
    func read() {
        Task {
            let operation = BleOperationRead(peripheral: peripheral, characteristic: characteristic)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
    
    func write(_ data: Data, withResponse: Bool = true) {
        Task {
            let operation = BleOperationRead(peripheral: peripheral, characteristic: characteristic)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
    
    func subscribe() {
        Task {
            let operation = BleOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: true)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
    
    func unsubscribe() {
        Task {
            let operation = BleOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: false)
            _ = try? await operationQueue?.enqueueOperation(operation)
        }
    }
}

// MARK: - Core Bluetooth protocols

extension BleCharacteristic: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }
        
        if let value = characteristic.value {
            self.data.send(value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == self.id else {
            assert(false, "Parent class called wrong characteristic's callback")
            return
        }
        
        self.isNotifying.send(characteristic.isNotifying)
    }
}
