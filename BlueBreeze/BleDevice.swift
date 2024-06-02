import CoreBluetooth
import Combine

enum BleDeviceConnectionStatus {
    case disconnected
    case connected
}

class BleDevice: NSObject {
    init(operationQueue: BleOperationQueue, peripheral: CBPeripheral) {
        self.operationQueue = operationQueue
        self.peripheral = peripheral
    }
    
    let operationQueue: BleOperationQueue
    let peripheral: CBPeripheral
    
    var id: UUID {
        get {
            return peripheral.identifier
        }
    }
    
    var name: String {
        get {
            return peripheral.name ?? ""
        }
    }
    
    var rssi: Int = 0
    
    var advertisementData: [String : Any] = [:]
    
    var isConnectable: Bool {
        get {
            return advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
        }
    }
    
    var advertisement: Data {
        get {
            return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data()
        }
    }
    
    var manufacturerId: Int? {
        get {
            return (advertisement.count > 2) ? (Int(advertisement[1]) << 8) | Int(advertisement[0]) : nil
        }
    }
    
    var manufacturer: String? {
        get {
            if let manufacturerId {
                return BleConstants.manufacturers[manufacturerId]
            }
            
            return nil
        }
    }
    
    var advertisedServices: [CBUUID] {
        get {
            return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        }
    }
    
    let services = CurrentValueSubject<[BleService], Never>([])
    
    // MARK: - Connection status
    
    let connectionStatus = CurrentValueSubject<BleDeviceConnectionStatus, Never>(.disconnected)
    
    // MARK: - MTU
    
    let mtu = CurrentValueSubject<Int, Never>(Int.defaultMtu)
    
    // MARK: - Operations
    
    func connect() async {
        do {
            try await operationQueue.enqueueOperation(BleOperationConnect(peripheral: peripheral))
            self.connectionStatus.send(.connected)
        } catch {
            self.connectionStatus.send(.disconnected)
        }
    }
    
    func disconnect() async {
        try? await operationQueue.enqueueOperation(BleOperationDisconnect(peripheral: peripheral))
        self.connectionStatus.send(.disconnected)
    }
    
    func discoverServices() async {
        try? await operationQueue.enqueueOperation(BleOperationDiscoverServices(peripheral: peripheral))
    }
    
    func requestMTU(_ mtu: Int) async {
        if let mtu = try? await operationQueue.enqueueOperation(BleOperationRequestMTU(peripheral: peripheral, targetMtu: 512)) {
            self.mtu.send(mtu)
        }
    }
}

extension BleDevice: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) { }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.services.send([])
        self.connectionStatus.send(.disconnected)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.services.send([])
        self.connectionStatus.send(.disconnected)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.services.send([])
        self.connectionStatus.send(.disconnected)
    }
}

extension BleDevice: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        self.getServiceWithUUID(service.uuid)?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.getCharacteristicWithUUID(characteristic.uuid)?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) { }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
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
