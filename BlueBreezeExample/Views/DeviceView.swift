//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine
import SwiftUI
import BlueBreeze

@MainActor
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
    
    var name: String? {
        device.name
    }
    
    // Connection
    
    @Published var connectionStatus: BBDeviceConnectionStatus = .disconnected
    @Published var executingConnection: Bool = false
    
    func connect() async {
        executingConnection = true
        defer {
            executingConnection = false
        }
        
        do {
            try await device.connect()
            try await device.discoverServices()
            try await device.requestMTU(512)
        } catch {
            // Ignore error
        }
    }
    
    func disconnect() async {
        executingConnection = true
        defer {
            executingConnection = false
        }
        
        do {
            try await device.disconnect()
        } catch {
            // Ignore error
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
                Section(
                    header: Text(BBConstants.knownServices[key]?.uppercased() ?? key.uuidString)
                ) {
                    ForEach(value) {
                        CharacteristicView(characteristic: $0)
                    }
                }
            }
        }
#if os(iOS)
        .listStyle(.grouped)
#endif
        .navigationTitle(viewModel.name ?? "Unknown device")
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
