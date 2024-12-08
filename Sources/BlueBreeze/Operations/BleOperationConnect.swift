import CoreBluetooth

class BleOperationConnect: BleOperationImpl<Void> {
    override func execute(_ centralManager: CBCentralManager) {
        centralManager.connect(peripheral)
    }

    override func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        completeSuccess(())
    }
    
    override func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        completeError(BleError(message: error?.localizedDescription ?? ""))
    }
}
