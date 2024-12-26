import SwiftUI

struct DeviceView: View {
    @EnvironmentObject var deviceViewModel: DeviceViewModel

    var body: some View {
        List {
            ForEach(deviceViewModel.services.sorted(by: {
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
        .navigationTitle(deviceViewModel.name)
        .toolbar {
            if deviceViewModel.executingConnection {
                ProgressView()
            } else if deviceViewModel.connectionStatus == .connected {
                Button {
                    Task {
                        await deviceViewModel.disconnect()
                    }
                } label: {
                    Text("Disconnect")
                }
            } else {
                Button {
                    Task {
                        await deviceViewModel.connect()
                    }
                } label: {
                    Text("Connect")
                }
            }
        }
        .onAppear {
        }
    }
}
