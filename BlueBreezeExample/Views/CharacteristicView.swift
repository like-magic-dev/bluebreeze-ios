//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine
import SwiftUI
import BlueBreeze

class CharacteristicViewModel: ObservableObject {
    init(characteristic: BBCharacteristic) {
        self.characteristic = characteristic
        
        characteristic.data
            .receive(on: DispatchQueue.main)
            .sink { self.data = $0 }
            .store(in: &dispatchBag)
        
        characteristic.isNotifying
            .receive(on: DispatchQueue.main)
            .sink { self.isNotifying = $0 }
            .store(in: &dispatchBag)
    }

    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // BLE characteristic

    let characteristic: BBCharacteristic
    
    // Properties
    
    var id: String {
        BBAssignedNumbers.characteristicUUIDs[characteristic.id]?.uppercased() ?? characteristic.id.uuidString }
    
    var canRead: Bool { characteristic.properties.contains(.read) }
    
    var canWrite: Bool { characteristic.properties.contains(.writeWithResponse) || characteristic.properties.contains(.writeWithoutResponse) }

    var canNotify: Bool { characteristic.properties.contains(.notify) }
    
    @Published var isNotifying: Bool = false

    // Data
    
    @Published var data: Data = Data()
    
    // Write data
    
    @Published var writeString: String = ""
    @Published var writePopup = false
    
    // Operations
    
    func read() async -> Data? {
        return try? await characteristic.read()
    }
    
    func write(data: Data) async {
        let withResponse = characteristic.properties.contains(.writeWithResponse)
        try? await characteristic.write(data, withResponse: withResponse)
    }
    
    func subscribe() async {
        try? await characteristic.subscribe()
    }
    
    func unsubscribe() async {
        try? await characteristic.unsubscribe()
    }
}

struct CharacteristicView: View {
    @StateObject var viewModel: CharacteristicViewModel

    init(characteristic: BBCharacteristic) {
        _viewModel = StateObject(wrappedValue: CharacteristicViewModel(characteristic: characteristic))
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.id).font(.caption)
                Text(viewModel.data.isEmpty ? "-" : viewModel.data.hexString)
            }
            Spacer()
            if viewModel.canRead {
                Button("Read") {
                    Task {
                        await viewModel.read()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            if viewModel.canWrite {
                Button("Write") {
                    viewModel.writePopup = true
                }
                .buttonStyle(.borderedProminent)
                .popover(
                    isPresented: $viewModel.writePopup
                ) {
                    VStack(spacing: 16) {
                        TextField("Enter data", text: $viewModel.writeString)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor((viewModel.writeString.hexData == nil) ? .red : nil)
                        HStack(spacing: 16) {
                            Spacer()
                            Button("Close") {
                                viewModel.writePopup = false
                            }
                            .buttonStyle(.plain)
                            Button("Write") {
                                viewModel.writePopup = false
                                
                                if let hexData = viewModel.writeString.hexData {
                                    Task {
                                        await viewModel.write(data: hexData)
                                    }
                                }
                            }
                            .disabled(viewModel.writeString.hexData == nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(minWidth: 250)
                    .padding(16)
                }
            }
            if viewModel.canNotify {
                if viewModel.isNotifying {
                    Button("Unsubscribe") {
                        Task {
                            await viewModel.unsubscribe()
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Subscribe") {
                        Task {
                            await viewModel.subscribe()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

extension Data {
    var hexString: String { map(\.hexString).joined() }
}

extension UInt8 {
    var hexString: String { String(format: "%02X", self) }
}

extension String {
    var hexData: Data? {
        guard self.count % 2 == 0 else {
            return nil
        }
        
        var data = Data()
        
        var index = self.startIndex
        while index < self.endIndex {
            let nextIndex = self.index(index, offsetBy: 2)
            let hexSubstring = self[index..<nextIndex]
            
            if let byte = UInt8(hexSubstring, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            
            index = nextIndex
        }
        
        return data
    }
}
