import SwiftUI
import Combine
import BlueBreeze

class DeviceViewModel: ObservableObject {
    init(device: BleDevice) {
        self.device = device
    }

    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // BLE device

    let device: BleDevice
    
    // Properties
    
    var name: String {
        device.name
    }
}
