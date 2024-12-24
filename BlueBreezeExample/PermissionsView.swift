import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            Text("The app is not authorized")
            if viewModel.authorizationStatus == .unknown {
                Button {
                    viewModel.authorize()
                } label: {
                    Text("Show authorization popup")
                }
            } else {
                Text("Please grant authorization in the settings")
            }
        }
        .navigationTitle("BLE Authorization")
    }
}
