import CoreBluetooth
import Combine

public class BBDevice: NSObject {
    init(operationQueue: BBOperationQueue, peripheral: CBPeripheral) {
        self.operationQueue = operationQueue
        self.peripheral = peripheral
    }
    
    let operationQueue: BBOperationQueue
    let peripheral: CBPeripheral
    
    public var id: UUID {
        get {
            return peripheral.identifier
        }
    }
    
    public var name: String {
        get {
            return peripheral.name ?? ""
        }
    }
    
    public var rssi: Int = 0
    
    public var advertisementData: [String : Any] = [:]
    
    public var isConnectable: Bool {
        get {
            return advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
        }
    }
    
    public var advertisement: Data {
        get {
            return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data()
        }
    }
    
    public var manufacturerId: Int? {
        get {
            return (advertisement.count > 2) ? (Int(advertisement[1]) << 8) | Int(advertisement[0]) : nil
        }
    }
    
    public var manufacturer: String? {
        get {
            if let manufacturerId {
                return BBConstants.manufacturers[manufacturerId]
            }
            
            return nil
        }
    }
    
    public var advertisedServices: [BBUUID] {
        get {
            return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        }
    }
    
    public let services = CurrentValueSubject<[BBUUID: [BBCharacteristic]], Never>([:])
    
    // MARK: - Connection status
    
    public let connectionStatus = CurrentValueSubject<BBDeviceConnectionStatus, Never>(.disconnected)
    
    // MARK: - MTU
    
    public let mtu = CurrentValueSubject<Int, Never>(Int.defaultMtu)
    
    // MARK: - Operations
    
    public func connect() async {
        do {
            try await operationQueue.enqueueOperation(BBOperationConnect(peripheral: peripheral))
            self.connectionStatus.value = .connected
        } catch {
            self.connectionStatus.value = .disconnected
        }
    }
    
    public func disconnect() async {
        try? await operationQueue.enqueueOperation(BBOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.value = .disconnected
    }
    
    public func discoverServices() async {
        try? await operationQueue.enqueueOperation(BBOperationDiscoverServices(peripheral: peripheral))
    }
    
    public func requestMTU(_ mtu: Int) async {
        if let mtu = try? await operationQueue.enqueueOperation(BBOperationRequestMTU(peripheral: peripheral, targetMtu: 512)) {
            self.mtu.value = mtu
        }
    }
}

extension BBDevice: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) { }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.services.value = [:]
        self.connectionStatus.value = .disconnected
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
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        var characteristics = self.services.value[service.uuid] ?? []
        
        service.characteristics?.forEach({ characteristic in
            if !characteristics.contains(where: { $0.id == characteristic.uuid }) {
                characteristics.append(
                    BBCharacteristic(
                        peripheral: peripheral,
                        characteristic: characteristic,
                        operationQueue: self.operationQueue
                    )
                )
            }
        })

        var services = self.services.value
        services[service.uuid] = characteristics
        self.services.value = services
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) { }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
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
