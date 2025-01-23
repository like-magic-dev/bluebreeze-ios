//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

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
    
    public var properties: Set<BBCharacteristicProperty> {
        get {
            var result = Set<BBCharacteristicProperty>()
            if characteristic.properties.contains(.read) {
                result.insert(.read)
            }
            if characteristic.properties.contains(.write) {
                result.insert(.writeWithResponse)
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                result.insert(.writeWithoutResponse)
            }
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                result.insert(.notify)
            }
            return result
        }
    }

    // MARK: - Operations
    
    public func read() async throws {
        let operation = BBOperationRead(peripheral: peripheral, characteristic: characteristic)
        _ = try await operationQueue?.operationEnqueue(operation)
    }
    
    public func write(_ data: Data, withResponse: Bool = true) async throws {
        let operation = BBOperationWrite(peripheral: peripheral, characteristic: characteristic, data: data, withResponse: withResponse)
        _ = try? await operationQueue?.operationEnqueue(operation)
    }
    
    public func subscribe() async throws {
        let operation = BBOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: true)
        _ = try? await operationQueue?.operationEnqueue(operation)
    }
    
    public func unsubscribe() async throws {
        let operation = BBOperationNotifications(peripheral: peripheral, characteristic: characteristic, enabled: false)
        _ = try? await operationQueue?.operationEnqueue(operation)
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
