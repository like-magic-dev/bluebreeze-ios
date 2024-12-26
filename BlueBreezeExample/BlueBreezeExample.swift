//
//  BlueBreezeExample.swift
//  BlueBreezeTest
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI

@main
struct BlueBreezeExample: App {
    @ObservedObject var viewModel = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if viewModel.authorizationStatus != .authorized {
                    PermissionsView()
                } else if viewModel.state != .poweredOn {
                    OfflineView()
                } else {
                    ScanningView()
                }
            }
        }
        .environmentObject(viewModel)
    }
}
