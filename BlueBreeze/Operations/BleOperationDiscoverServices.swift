import CoreBluetooth

class BleOperationDiscoverServices: BleOperationImpl<Void> {
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.discoverServices(nil)
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            completeError(error)
            return
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            completeError(error)
            return
        }
        
        // A missing service means that discovery is not complete
        if peripheral.services?.contains(where: { $0.characteristics == nil }) == true {
            return
        }
        
        completeSuccess(())
    }
}