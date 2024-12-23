import SwiftUI

struct ScanningView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            if viewModel.isScanning {
                Button {
                    viewModel.stopScanning()
                } label: {
                    Text("Stop scanning")
                }
            } else {
                Button {
                    viewModel.startScanning()
                } label: {
                    Text("Start scanning")
                }
            }
            
            List(viewModel.devices) { device in
                Text(device.name)
            }
        }
        .padding()
    }
}
