//
//  ContentView.swift
//  BlueBreezeTest
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
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
}
