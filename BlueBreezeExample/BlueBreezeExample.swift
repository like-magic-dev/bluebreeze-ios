//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import SwiftUI
import BlueBreeze

@main
struct BlueBreezeExample: App {
    let manager = BBManager()
        
    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    HomeView(manager: manager)
                }
            } else {
                NavigationView {
                    HomeView(manager: manager)
                }
            }
        }
    }
}
