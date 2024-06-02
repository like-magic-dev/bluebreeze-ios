import CoreBluetooth

class BleOperationNotifications: BleOperationImpl<Void> {
    let characteristic: CBCharacteristic
    let enabled: Bool
    
    init(
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        enabled: Bool,
        continuation: BleContinuation<Void>? = nil
    ) {
        self.characteristic = characteristic
        self.enabled = enabled
        super.init(peripheral: peripheral, continuation: continuation)
    }
    
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if self.characteristic == characteristic {
            if let error = error {
                completeError(error)
                return
            }

            completeSuccess(())
        }
    }
}
