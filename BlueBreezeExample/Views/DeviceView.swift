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
            try await device.negotiateMTU()
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

    @Published var services: [BBService] = []
}

struct DeviceView: View {
    @StateObject var viewModel: DeviceViewModel

    init(device: BBDevice) {
        _viewModel = StateObject(wrappedValue: DeviceViewModel(device: device))
    }

    var body: some View {
        List {
            // Keyed by `uuid` (the service's stable GATT identity), not `\.self`: BBService is a
            // struct, so `\.self` would bake in its current `characteristics` snapshot, forcing
            // the whole section to be torn down and rebuilt on every incremental characteristic
            // discovered, rather than just updating in place.
            ForEach(viewModel.services.sorted(by: {
                $0.uuid.uuidString < $1.uuid.uuidString
            }), id: \.uuid) { service in
                Section(
                    header: Text(service.name?.uppercased() ?? service.uuid.uuidString)
                ) {
                    // NOTE: Do not key by BBCharacteristic UUID or you will get stale instances on reconnect
                    ForEach(service.characteristics, id: \.self) {
                        CharacteristicView(characteristic: $0)
                    }
                }
            }
        }
        .buttonStyle(.borderless)
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
