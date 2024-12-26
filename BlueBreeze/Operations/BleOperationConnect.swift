import CoreBluetooth

class BBOperationConnect: BBOperationImpl<Void> {
    override func execute(_ centralManager: CBCentralManager) {
        centralManager.connect(peripheral)
    }

    override func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        completeSuccess(())
    }
    
    override func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        completeError(BBError(message: error?.localizedDescription ?? ""))
    }
}
