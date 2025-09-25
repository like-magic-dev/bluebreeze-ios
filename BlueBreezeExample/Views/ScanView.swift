//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine
import SwiftUI
import BlueBreeze

class ScanViewModel: ObservableObject {
    init(manager: BBManager) {
        self.manager = manager
        
        manager.scanEnabled
            .receive(on: DispatchQueue.main)
            .sink { self.scanEnabled = $0 }
            .store(in: &dispatchBag)
        
        manager.scanResults
            .receive(on: DispatchQueue.main)
            .sink { self.scanResults[$0.device.id] = $0 }
            .store(in: &dispatchBag)
    }
    
    let manager: BBManager
    
    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // Scan
    
    @Published var scanEnabled: Bool = false
    
    @Published var scanResults: [UUID: BBScanResult] = [:]

    func scanStart() {
        manager.scanStart()
    }
    
    func scanStop() {
        manager.scanStop()
    }
}

struct ScanView: View {
    @StateObject var viewModel: ScanViewModel

    init(manager: BBManager) {
        _viewModel = StateObject(wrappedValue: ScanViewModel(manager: manager))
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
        .navigationTitle("BLE Scan")
        .toolbar {
            if viewModel.scanEnabled {
                Button {
                    viewModel.scanStop()
                } label: {
                    Image(systemName: "stop.fill")
                }
            } else {
                Button {
                    viewModel.scanStart()
                } label: {
                    Image(systemName: "play.fill")
                }
            }
        }
        .onAppear {
            viewModel.scanStart()
        }
        .onDisappear {
            viewModel.scanStop()
        }
    }
}
