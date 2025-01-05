//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import BlueBreeze
import Combine
import SwiftUI

class HomeViewModel: ObservableObject {
    init(manager: BBManager) {
        self.manager = manager
        
        manager.authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { self.authorizationStatus = $0 }
            .store(in: &dispatchBag)
        
        manager.state
            .receive(on: DispatchQueue.main)
            .sink { self.state = $0 }
            .store(in: &dispatchBag)
    }
    
    let manager: BBManager
    
    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // Authorization
    
    @Published var authorizationStatus: BBAuthorization = .unknown
    
    func authorize() {
        manager.authorizationRequest()
    }
    
    // Online
    
    @Published var state: BBState = .unknown
}

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    init(manager: BBManager) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(manager: manager))
    }
    
    var body: some View {
        if viewModel.authorizationStatus != .authorized {
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
        } else if viewModel.state != .poweredOn {
            VStack {
                Text("Bluetooth offline")
            }
            .navigationTitle("BLE Offline")
        } else {
            ScanningView(manager: viewModel.manager)
        }
    }
}
