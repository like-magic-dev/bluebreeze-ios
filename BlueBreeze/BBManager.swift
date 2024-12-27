import Foundation
import CoreBluetooth
import Combine

public class BBManager: NSObject, BBOperationQueue {
    public override init() {
        super.init()
        
        authorizationStatus.value = CBCentralManager.authorization.bleAuthorization
        
        if authorizationStatus.value == .authorized {
            state.value = centralManager.state.bbState
        }
    }
    
    // MARK: - Central manager instance, initialized on first access
    
    let centralManagerQueue = DispatchQueue(label: "BBOperationQueue", qos: .userInteractive)
    
    lazy var centralManager = CBCentralManager(delegate: self, queue: centralManagerQueue)
    
    // MARK: - Permissions

    public let authorizationStatus = CurrentValueSubject<BBAuthorization, Never>(.unknown)

    public func authorizationRequest() {
        // Creating the object causes a popup request on iOS 13.1+
        _ = centralManager
    }
    
    // MARK: - Online
    
    public let state = CurrentValueSubject<BBState, Never>(.unknown)

    // MARK: - Devices
    
    public let devices = CurrentValueSubject<[UUID: BBDevice], Never>([:])

    // MARK: - Scanning
    
    public let isScanning = CurrentValueSubject<Bool, Never>(false)
    
    public func scanningStart() {
        guard !isScanning.value else {
            return
        }

        centralManager.scanForPeripherals(withServices: nil)
        isScanning.value = true
    }
    
    public func scanningStop() {
        guard isScanning.value else {
            return
        }

        centralManager.stopScan()
        isScanning.value = false
    }
    
    // MARK: - Operation queue
    
    var operationCurrent: (any BBOperation)?
    var operationQueue: [any BBOperation] = []
    var operationLock = NSLock()

    func enqueueOperation<RESULT, OP: BBOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT {
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
            
            centralManagerQueue.asyncAfter(deadline: .now() + operationCurrent.timeOut) {
                if !operationCurrent.isCompleted {
                    operationCurrent.cancel()
                }
            }
            
            self.checkOperation()
        }
    }
}

extension BBManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        authorizationStatus.value = CBCentralManager.authorization.bleAuthorization
        state.value = central.state.bbState

        if isScanning.value && central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil)
        }
        
        operationCurrent?.centralManagerDidUpdateState(central)
        checkOperation()
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
                
        var devices = self.devices.value
        
        let device = devices[peripheral.identifier] ?? BBDevice(operationQueue: self, peripheral: peripheral)
        device.advertisementData = advertisementData
        device.rssi = RSSI.intValue
        
        devices[peripheral.identifier] = device
        self.devices.value = devices
        
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

extension BBManager: CBPeripheralDelegate {
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
