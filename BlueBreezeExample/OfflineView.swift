import SwiftUI

struct OfflineView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            Text("Bluetooth offline")
        }
        .padding()
    }
}
