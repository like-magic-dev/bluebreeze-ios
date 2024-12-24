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
//            if viewModel.isScanning {
//                Button {
//                    viewModel.stopScanning()
//                } label: {
//                    Image(systemName: "stop.fill")
//                }
//            } else {
//                Button {
//                    viewModel.startScanning()
//                } label: {
//                    Image(systemName: "play.fill")
//                }
//            }
        }
        .onAppear {
        }
    }
}
