import Combine
import SwiftUI
import BlueBreeze

class DeviceViewModel: ObservableObject {
    init(device: BBDevice) {
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

    let device: BBDevice
    
    // Properties
    
    var name: String {
        device.name
    }
    
    // Connection
    
    @Published var connectionStatus: BBDeviceConnectionStatus = .disconnected
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
    
    @Published var services: [BBUUID: [BBCharacteristic]] = [:]
}

struct DeviceView: View {
    @StateObject var viewModel: DeviceViewModel

    init(device: BBDevice) {
        _viewModel = StateObject(wrappedValue: DeviceViewModel(device: device))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.services.sorted(by: {
                $0.key.uuidString < $1.key.uuidString
            }), id: \.key) { key, value in
                Section(header: Text(key.uuidString)) {
                    ForEach(value) {
                        Text($0.id.uuidString)
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(viewModel.name)
        .toolbar {
            if viewModel.executingConnection {
                ProgressView()
            } else if viewModel.connectionStatus == .connected {
                Button {
                    Task {
                        await viewModel.disconnect()
                    }
                } label: {
                    Text("Disconnect")
                }
            } else {
                Button {
                    Task {
                        await viewModel.connect()
                    }
                } label: {
                    Text("Connect")
                }
            }
        }
    }
}
