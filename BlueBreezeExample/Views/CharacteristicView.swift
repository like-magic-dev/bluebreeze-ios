import Combine
import SwiftUI
import BlueBreeze

class CharacteristicViewModel: ObservableObject {
    init(characteristic: BBCharacteristic) {
        self.characteristic = characteristic
        
        characteristic.data
            .receive(on: DispatchQueue.main)
            .sink { self.data = $0.hexString }
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
        BBConstants.knownCharacteristics[characteristic.id]?.uppercased() ?? characteristic.id.uuidString }
    
    var canRead: Bool { characteristic.canRead }
    
    var canWrite: Bool { characteristic.canWrite || characteristic.canWriteWithoutResponse }

    var canNotify: Bool { characteristic.canNotify }
    
    @Published var isNotifying: Bool = false

    // Data
    
    @Published var data: String = ""
    
    // Operations
    
    func read() {
        characteristic.read()
    }
    
    func write(data: Data) {
        characteristic.write(data)
    }
    
    func subscribe() {
        characteristic.subscribe()
    }
    
    func unsubscribe() {
        characteristic.unsubscribe()
    }
}

struct CharacteristicView: View {
    @StateObject var viewModel: CharacteristicViewModel
    @State var validData: Bool = true

    init(characteristic: BBCharacteristic) {
        _viewModel = StateObject(wrappedValue: CharacteristicViewModel(characteristic: characteristic))
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.id).font(.caption)
                HStack {
                    TextField("No value", text: $viewModel.data)
                        .onReceive(Just(viewModel.data), perform: { value in
                            validData = (value.hexData != nil)
                        })
                        .foregroundColor(validData ? Color(uiColor: .darkText) : .red)
                        .disabled(!viewModel.canWrite)
                }
            }
            Spacer()
            if viewModel.canRead {
                Button("Read") {
                    viewModel.read()
                }
                .buttonStyle(.borderedProminent)
            }
            if viewModel.canWrite {
                Button("Write") {
                    if let hexData = viewModel.data.hexData {
                        viewModel.write(data: hexData)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            if viewModel.canNotify {
                if viewModel.isNotifying {
                    Button("Unsubscribe") {
                        viewModel.unsubscribe()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Subscribe") {
                        viewModel.subscribe()
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
