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
        do {
            try await operationEnqueue(BBOperationConnect(peripheral: peripheral))
            self.connectionStatus.value = .connected
        } catch let error {
            self.connectionStatus.value = .disconnected
            throw error
        }
    }
    
    public func disconnect() async throws {
        try await operationEnqueue(BBOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.value = .disconnected
    }
    
    public func discoverServices() async throws {
        try? await operationEnqueue(BBOperationDiscoverServices(peripheral: peripheral))
    }
    
    public func requestMTU(_ mtu: Int) async throws {
        if let mtu = try? await operationEnqueue(BBOperationRequestMTU(peripheral: peripheral, targetMtu: 512)) {
            self.mtu.value = mtu
        }
    }
    
    // MARK: - Operation queue
    
    var operationCurrent: (any BBOperation)?
    var operationQueue: [any BBOperation] = []
    var operationLock = NSLock()

    func operationEnqueue<RESULT, OP: BBOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT {
        return try await withCheckedThrowingContinuation { continuation in
            operation.continuation = continuation
            
            operationLock.lock()
            operationQueue.append(operation)
            operationLock.unlock()
            
            operationCheck()
        }
    }
    
    private func operationCheck() {
        operationLock.lock()
        
        if let operationCurrent = operationCurrent, !operationCurrent.isCompleted {
            operationLock.unlock()
            return
        }
        
        operationCurrent = operationQueue.popFirst()
        
        operationLock.unlock()
        
        if let operationCurrent = operationCurrent {
            operationCurrent.execute(self.centralManager)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + operationCurrent.timeOut) {
                if !operationCurrent.isCompleted {
                    operationCurrent.cancel()
                }
            }
            
            self.operationCheck()
        }
    }
}

extension BBDevice: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        operationCurrent?.centralManagerDidUpdateState(central)
        operationCheck()
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        operationCurrent?.centralManager?(central, didConnect: peripheral)
        operationCheck()
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected
        
        operationCurrent?.centralManager?(central, didFailToConnect: peripheral, error: error)
        operationCheck()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected
        
        operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        operationCheck()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected
        
        operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
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
        
        operationCurrent?.peripheral?(peripheral, didDiscoverServices: error)
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
        
        operationCurrent?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        operationCheck()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
        
        operationCurrent?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        operationCheck()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        operationCurrent?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        operationCheck()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        
        operationCurrent?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        operationCheck()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
        
        operationCurrent?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        operationCheck()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        if let characteristic = descriptor.characteristic {
            getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
        }
        
        operationCurrent?.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
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
