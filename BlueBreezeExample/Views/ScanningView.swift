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
        
        manager.isScanning
            .receive(on: DispatchQueue.main)
            .sink { self.isScanning = $0 }
            .store(in: &dispatchBag)
        
        manager.devices
            .receive(on: DispatchQueue.main)
            .sink { self.devices = $0.values.map { $0 } }
            .store(in: &dispatchBag)
    }
    
    let manager: BBManager
    
    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // Scanning
    
    @Published var isScanning: Bool = false
    
    func startScanning() {
        manager.scanningStart()
    }
    
    func stopScanning() {
        manager.scanningStop()
    }
    
    // Devices
    
    @Published var devices: [BBDevice] = []
}

struct ScanningView: View {
    @StateObject var viewModel: ScanningViewModel

    init(manager: BBManager) {
        _viewModel = StateObject(wrappedValue: ScanningViewModel(manager: manager))
    }
    
    var body: some View {
        List(viewModel.devices) { device in
            NavigationLink {
                DeviceView(device: device)
            } label: {
                HStack {
                    Text(device.name)
                    Spacer()
                    Text("\(device.rssi)")
                }
            }
        }
        .navigationTitle("BLE Scanning")
        .toolbar {
            if viewModel.isScanning {
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
