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
        
        manager.scanningResults
            .receive(on: DispatchQueue.main)
            .sink { self.scanResults[$0.id] = $0 }
            .store(in: &dispatchBag)
    }
    
    let manager: BBManager
    
    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // Scanning
    
    @Published var scanningEnabled: Bool = false
    
    @Published var scanResults: [UUID: BBScanResult] = [:]

    func startScanning() {
        manager.scanningStart()
    }
    
    func stopScanning() {
        manager.scanningStop()
    }
}

struct ScanningView: View {
    @StateObject var viewModel: ScanningViewModel

    init(manager: BBManager) {
        _viewModel = StateObject(wrappedValue: ScanningViewModel(manager: manager))
    }
    
    var body: some View {
        List(viewModel.scanResults.sorted(by: { $0.key.uuidString > $1.key.uuidString }), id: \.key) { key, scanResult in
            NavigationLink {
                DeviceView(device: scanResult.device)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(scanResult.name ?? "-")
                        Text(scanResult.manufacturerName ?? "-").font(.caption)
                        if !scanResult.advertisedServices.isEmpty {
                            Text(scanResult.advertisedServices.map { $0.uuidString }.joined(separator: ", ")).font(.caption2)
                        }
                    }
                    Spacer()
                    Text("\(scanResult.rssi)")
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
