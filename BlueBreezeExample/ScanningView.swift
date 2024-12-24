import SwiftUI

struct ScanningView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        List(viewModel.devices) { device in
            NavigationLink {
                
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
    }
}
