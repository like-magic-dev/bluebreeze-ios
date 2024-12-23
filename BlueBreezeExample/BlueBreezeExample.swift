//
//  BlueBreezeExample.swift
//  BlueBreezeTest
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI

@main
struct BlueBreezeExample: App {
    let viewModel = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .environmentObject(viewModel)
    }
}
