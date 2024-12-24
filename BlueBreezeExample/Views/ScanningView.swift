import SwiftUI

struct ScanningView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        List(viewModel.devices) { device in
            NavigationLink {
                DeviceView()
                    .environmentObject(DeviceViewModel(device: device))
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
