import Foundation
import CoreBluetooth
import Combine

class BleManager: NSObject {
    override init() {
        super.init()
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "BleOperationQueue", qos: .userInteractive)
        )
    }
    
    var centralManager: CBCentralManager!
        
    // MARK: - Devices
    
    let devices = CurrentValueSubject<[UUID: BleDevice], Never>([:])

    // MARK: - Scanning
    
    let isScanning = CurrentValueSubject<Bool, Never>(false)
    
    func scanningStart() {
        guard !isScanning.value else {
            return
        }
                
        centralManager.scanForPeripherals(withServices: nil)
        isScanning.send(true)
    }
    
    func scanningStop() {
        guard isScanning.value else {
            return
        }
        
        centralManager.stopScan()
        isScanning.send(false)
    }
    
    // MARK: - Operation queue
    
    var operationCurrent: (any BleOperation)?
    var operationQueue: [any BleOperation] = []
    var operationLock = NSLock()
}

extension BleManager: BleOperationQueue {
    func enqueueOperation<RESULT, OP: BleOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT {
        return try await withCheckedThrowingContinuation { continuation in
            operation.continuation = continuation
            
            operationLock.lock()
            operationQueue.append(operation)
            operationLock.unlock()
            
            checkOperation()
        }
    }
    
    private func checkOperation() {
        operationLock.lock()
        
        if let operationCurrent = operationCurrent, !operationCurrent.isCompleted {
            operationLock.unlock()
            return
        }
        
        operationCurrent = operationQueue.popFirst()
        
        operationLock.unlock()
        
        if let operationCurrent = operationCurrent {
            operationCurrent.execute(self.centralManager)
            self.checkOperation()
        }
    }
}

extension BleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            scanningStop()
        } else {
            scanningStart()
        }
        
        operationCurrent?.centralManagerDidUpdateState(central)
        checkOperation()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
                
        var devices = self.devices.value
        
        let device = devices[peripheral.identifier] ?? BleDevice(operationQueue: self, peripheral: peripheral)
        device.advertisementData = advertisementData
        device.rssi = RSSI.intValue
        
        devices[peripheral.identifier] = device
        self.devices.send(devices)
        
        operationCurrent?.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        checkOperation()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        devices.value[peripheral.identifier]?.centralManager(central, didConnect: peripheral)
        
        operationCurrent?.centralManager?(central, didConnect: peripheral)
        checkOperation()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didFailToConnect: peripheral, error: error)

        operationCurrent?.centralManager?(central, didFailToConnect: peripheral, error: error)
        checkOperation()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didDisconnectPeripheral: peripheral, error: error)

        operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        checkOperation()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)

        operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        checkOperation()
    }
}

extension BleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didDiscoverServices: error)

        operationCurrent?.peripheral?(peripheral, didDiscoverServices: error)
        checkOperation()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)

        operationCurrent?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        checkOperation()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)

        operationCurrent?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        checkOperation()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateValueFor: descriptor, error: error)
        
        operationCurrent?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        checkOperation()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        
        operationCurrent?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        checkOperation()
    }
}

extension Array where Element: Any {
    mutating func push(_ element: Self.Element) {
        append(element)
    }

    mutating func popFirst() -> Self.Element? {
        guard let first = first else {
            return nil
        }

        remove(at: 0)
        return first
    }
}
