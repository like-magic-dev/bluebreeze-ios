import CoreBluetooth

class BleOperationDisconnect: BleOperationImpl<Void> {
    override func execute(_ centralManager: CBCentralManager) {
        centralManager.cancelPeripheralConnection(peripheral)
    }

    override func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        if let error = error {
            completeError(error)
        } else {
            completeSuccess(())
        }
    }
    
    override func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        if let error = error {
            completeError(error)
            return
        }

        completeSuccess(())
    }
}
