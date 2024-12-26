import SwiftUI
import Combine
import BlueBreeze

class DeviceViewModel: ObservableObject {
    init(device: BleDevice) {
        self.device = device
        
        device.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { self.connectionStatus = $0 }
            .store(in: &dispatchBag)
        
        device.services
            .receive(on: DispatchQueue.main)
            .sink { self.services = $0 }
            .store(in: &dispatchBag)
    }

    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // BLE device

    let device: BleDevice
    
    // Properties
    
    var name: String {
        device.name
    }
    
    // Connection
    
    @Published var connectionStatus: BleDeviceConnectionStatus = .disconnected
    @Published var executingConnection: Bool = false
    
    func connect() async {
        DispatchQueue.main.async {
            self.executingConnection = true
        }
        
        await device.connect()
        await device.discoverServices()
        await device.requestMTU(512)
        
        DispatchQueue.main.async {
            self.executingConnection = false
        }
    }
    
    func disconnect() async {
        DispatchQueue.main.async {
            self.executingConnection = true
        }
        
        await device.disconnect()
        
        DispatchQueue.main.async {
            self.executingConnection = false
        }
    }
    
    // Characteristics
    
    @Published var services: [BBUUID: [BleCharacteristic]] = [:]
}
