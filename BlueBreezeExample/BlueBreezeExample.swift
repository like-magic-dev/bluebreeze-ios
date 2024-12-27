//
//  BlueBreezeExample.swift
//  BlueBreezeTest
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI
import BlueBreeze

@main
struct BlueBreezeExample: App {
    let manager = BBManager()
        
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(manager: manager)
            }
        }
    }
}
