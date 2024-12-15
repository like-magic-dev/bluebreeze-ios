import CoreBluetooth

class BleOperationWrite: BleOperationImpl<Void> {
    let characteristic: CBCharacteristic
    let data: Data
    let withResponse: Bool

    init(
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        data: Data,
        withResponse: Bool,
        continuation: BleContinuation<Void>? = nil
    ) {
        self.characteristic = characteristic
        self.data = data
        self.withResponse = withResponse
        super.init(peripheral: peripheral, continuation: continuation)
    }
    
    override func execute(_ centralManager: CBCentralManager) {
        peripheral.writeValue(data, for: characteristic, type: withResponse ? .withResponse : .withoutResponse)
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if self.characteristic == characteristic {
            if let error = error {
                completeError(error)
                return
            }

            completeSuccess(())
        }
    }
}
