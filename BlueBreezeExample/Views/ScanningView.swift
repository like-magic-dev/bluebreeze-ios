//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine
import SwiftUI
import BlueBreeze

class ScanningViewModel: ObservableObject {
    init(manager: BBManager) {
        self.manager = manager
        
        manager.scanningEnabled
            .receive(on: DispatchQueue.main)
            .sink { self.scanningEnabled = $0 }
            .store(in: &dispatchBag)
        
        manager.scanningDevices
            .receive(on: DispatchQueue.main)
            .sink { self.devices[$0.id] = $0 }
            .store(in: &dispatchBag)
    }
    
    let manager: BBManager
    
    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // Scanning
    
    @Published var scanningEnabled: Bool = false
    
    func startScanning() {
        manager.scanningStart()
    }
    
    func stopScanning() {
        manager.scanningStop()
    }
    
    // Devices
    
    @Published var devices: [UUID: BBDevice] = [:]
}

struct ScanningView: View {
    @StateObject var viewModel: ScanningViewModel

    init(manager: BBManager) {
        _viewModel = StateObject(wrappedValue: ScanningViewModel(manager: manager))
    }
    
    var body: some View {
        List(viewModel.devices.sorted(by: { $0.key.uuidString > $1.key.uuidString }), id: \.key) { key, device in
            NavigationLink {
                DeviceView(device: device)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(device.name ?? "-")
                        Text(device.manufacturerName ?? "-").font(.caption)
                        if !device.advertisedServices.isEmpty {
                            Text(device.advertisedServices.map { $0.uuidString }.joined(separator: ", ")).font(.caption2)
                        }
                    }
                    Spacer()
                    Text("\(device.rssi)")
                }
            }
        }
        .navigationTitle("BLE Scanning")
        .toolbar {
            if viewModel.scanningEnabled {
                Button {
                    viewModel.stopScanning()
                } label: {
                    Image(systemName: "stop.fill")
                }
            } else {
                Button {
                    viewModel.startScanning()
                } label: {
                    Image(systemName: "play.fill")
                }
            }
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
}
