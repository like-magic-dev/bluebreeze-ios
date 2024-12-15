import CoreBluetooth
import Combine

public enum BleDeviceConnectionStatus {
    case disconnected
    case connected
}

public class BleDevice: NSObject {
    init(operationQueue: BleOperationQueue, peripheral: CBPeripheral) {
        self.operationQueue = operationQueue
        self.peripheral = peripheral
    }
    
    let operationQueue: BleOperationQueue
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
                return BleConstants.manufacturers[manufacturerId]
            }
            
            return nil
        }
    }
    
    public var advertisedServices: [CBUUID] {
        get {
            return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        }
    }
    
    public let services = CurrentValueSubject<[BleService], Never>([])
    
    // MARK: - Connection status
    
    public let connectionStatus = CurrentValueSubject<BleDeviceConnectionStatus, Never>(.disconnected)
    
    // MARK: - MTU
    
    public let mtu = CurrentValueSubject<Int, Never>(Int.defaultMtu)
    
    // MARK: - Operations
    
    public func connect() async {
        do {
            try await operationQueue.enqueueOperation(BleOperationConnect(peripheral: peripheral))
            self.connectionStatus.send(.connected)
        } catch {
            self.connectionStatus.send(.disconnected)
        }
    }
    
    public func disconnect() async {
        try? await operationQueue.enqueueOperation(BleOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.send(.disconnected)
    }
    
    public func discoverServices() async {
        try? await operationQueue.enqueueOperation(BleOperationDiscoverServices(peripheral: peripheral))
    }
    
    public func requestMTU(_ mtu: Int) async {
        if let mtu = try? await operationQueue.enqueueOperation(BleOperationRequestMTU(peripheral: peripheral, targetMtu: 512)) {
            self.mtu.send(mtu)
        }
    }
}

extension BleDevice: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) { }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.services.send([])
        self.connectionStatus.send(.disconnected)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.services.send([])
        self.connectionStatus.send(.disconnected)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.services.send([])
        self.connectionStatus.send(.disconnected)
    }
}

extension BleDevice: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        peripheral.services?.forEach({ service in
            if !self.services.value.contains(where: { $0.id == service.uuid }) {
                var services = self.services.value
                services.append(
                    BleService(
                        peripheral: peripheral,
                        service: service,
                        operationQueue: self.operationQueue
                    )
                )
                self.services.send(services)
            }
        })
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        self.getServiceWithUUID(service.uuid)?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) { }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }
}

extension BleDevice: Identifiable { }

extension BleDevice {
    func getServiceWithUUID(_ uuid: CBUUID) -> BleService? {
        for service in services.value {
            if service.id == uuid {
                return service
            }
        }
        
        return nil
    }
    
    func getCharacteristicWithUUID(_ uuid: CBUUID) -> BleCharacteristic? {
        for service in services.value {
            for characteristic in service.characteristics.value {
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
