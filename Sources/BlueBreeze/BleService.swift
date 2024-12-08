import CoreBluetooth
import Combine

public class BleService: NSObject, CBPeripheralDelegate, Identifiable {
    init(peripheral: CBPeripheral, service: CBService, operationQueue: BleOperationQueue) {
        self.peripheral = peripheral
        self.service = service
        self.operationQueue = operationQueue
    }
    
    let peripheral: CBPeripheral
    let service: CBService
    
    weak var operationQueue: BleOperationQueue?
    
    public let characteristics = CurrentValueSubject<[BleCharacteristic], Never>([])
    
    // MARK: - Computed properties
    
    public var id: CBUUID {
        get {
            return service.uuid
        }
    }

    // MARK: - Core Bluetooth protocols

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard service.uuid == self.id else {
            assert(false, "Parent class called wrong service's callback")
            return
        }
        
        service.characteristics?.forEach({ characteristic in
            if !self.characteristics.value.contains(where: { $0.id == characteristic.uuid }) {
                var characteristics = self.characteristics.value
                characteristics.append(
                    BleCharacteristic(
                        peripheral: peripheral,
                        characteristic: characteristic,
                        operationQueue: self.operationQueue
                    )
                )
                self.characteristics.send(characteristics)
            }
        })
    }
}

