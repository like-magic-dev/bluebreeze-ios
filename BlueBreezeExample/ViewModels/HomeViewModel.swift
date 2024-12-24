//
//  ViewModel.swift
//  BlueBreeze
//
//  Created by Alessandro Mulloni on 17.12.24.
//

import SwiftUI
import Combine
import BlueBreeze

class HomeViewModel: ObservableObject {
    init() {
        bleManager.authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { self.authorizationStatus = $0 }
            .store(in: &dispatchBag)
        
        bleManager.state
            .receive(on: DispatchQueue.main)
            .sink { self.state = $0 }
            .store(in: &dispatchBag)
        
        bleManager.isScanning
            .receive(on: DispatchQueue.main)
            .sink { self.isScanning = $0 }
            .store(in: &dispatchBag)
        
        bleManager.devices
            .receive(on: DispatchQueue.main)
            .sink { self.devices = $0.values.map { $0 } }
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
    
    // Online
    
    @Published var state: BleState = .unknown

    // Scanning
    
    @Published var isScanning: Bool = false
    
    func startScanning() {
        bleManager.scanningStart()
    }
    
    func stopScanning() {
        bleManager.scanningStop()
    }
    
    // Devices
    
    @Published var devices: [BleDevice] = []
}
