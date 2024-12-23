//
//  ViewModel.swift
//  BlueBreeze
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI
import Combine
import BlueBreeze

class ViewModel: ObservableObject {
    init() {
        bleManager.authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { self.authorizationStatus = $0 }
            .store(in: &dispatchBag)
    }

    // Dispatch bag for all cancellables
    
    var dispatchBag: Set<AnyCancellable> = []
    
    // BLE manager

    let bleManager = BleManager()

    // Authorization
    
    @Published var authorizationStatus: BleAuthorization = .unknown
    
    func authorize() {
        bleManager.authorizationRequest()
    }
}
