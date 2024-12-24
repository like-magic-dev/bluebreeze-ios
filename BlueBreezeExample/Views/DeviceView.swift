import SwiftUI

struct DeviceView: View {
    @EnvironmentObject var deviceViewModel: DeviceViewModel

    var body: some View {
//        List(viewModel.devices) { device in
//            NavigationLink {
//                
//            } label: {
//                HStack {
//                    Text(device.name)
//                    Spacer()
//                    Text("\(device.rssi)")
//                }
//            }
//        }
        Text(deviceViewModel.name)
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
