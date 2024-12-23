//
//  ContentView.swift
//  BlueBreezeTest
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        if viewModel.authorizationStatus == .authorized {
            DevicesView()
        } else {
            PermissionsView()
        }
    }
}
