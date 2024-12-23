import Foundation
import CoreBluetooth
import Combine

public class BleManager: NSObject {
    public override init() {
        super.init()
        authorizationStatus.value = getAuthorization()
    }
    
    // MARK: - Central manager instance, initialized on first access
    
    lazy var centralManager = CBCentralManager(
        delegate: self,
        queue: DispatchQueue(label: "BleOperationQueue", qos: .userInteractive)
    )
    
    // MARK: - Permissions

    private func getAuthorization() -> BleAuthorization {
        if #available(iOS 13.1, *) {
            return CBManager.authorization.bleAuthorization
        } else {
            // Causes an immediate permissions popup
            return centralManager.authorization.bleAuthorization
        }
    }
    
    public let authorizationStatus = CurrentValueSubject<BleAuthorization, Never>(.unknown)

    public func authorizationRequest() {
        // Creating the object causes a popup request also on iOS 13.1+
        authorizationStatus.value = centralManager.authorization.bleAuthorization
    }
    
    // MARK: - Devices
    
    public let devices = CurrentValueSubject<[UUID: BleDevice], Never>([:])

    // MARK: - Scanning
    
    public let isScanning = CurrentValueSubject<Bool, Never>(false)
    
    public func scanningStart() {
        guard !isScanning.value else {
            return
        }
                
        centralManager.scanForPeripherals(withServices: nil)
        isScanning.send(true)
    }
    
    public func scanningStop() {
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
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {        
        authorizationStatus.value = getAuthorization()

        if central.state != .poweredOn {
            scanningStop()
        } else {
            scanningStart()
        }
        
        operationCurrent?.centralManagerDidUpdateState(central)
        checkOperation()
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
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
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        devices.value[peripheral.identifier]?.centralManager(central, didConnect: peripheral)
        
        operationCurrent?.centralManager?(central, didConnect: peripheral)
        checkOperation()
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didFailToConnect: peripheral, error: error)

        operationCurrent?.centralManager?(central, didFailToConnect: peripheral, error: error)
        checkOperation()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didDisconnectPeripheral: peripheral, error: error)

        operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        checkOperation()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)

        operationCurrent?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        checkOperation()
    }
}

extension BleManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didDiscoverServices: error)

        operationCurrent?.peripheral?(peripheral, didDiscoverServices: error)
        checkOperation()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)

        operationCurrent?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        checkOperation()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)

        operationCurrent?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        checkOperation()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateValueFor: descriptor, error: error)
        
        operationCurrent?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        checkOperation()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
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
