//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Foundation
import CoreBluetooth
import Combine

public class BBManager: NSObject {
    public override init() {
        super.init()
        
        if #available(iOS 13.1, *) {
            authorizationStatus.value = CBCentralManager.authorization.bleAuthorization
        } else {
            authorizationStatus.value = centralManager.authorization.bleAuthorization
        }
        
        if authorizationStatus.value == .authorized {
            state.value = centralManager.state.bbState
        }
    }
    
    // MARK: - Central manager instance, initialized on first access
    
    let centralManagerQueue = DispatchQueue(label: "BBOperationQueue", qos: .userInteractive)
    
    lazy var centralManager = CBCentralManager(delegate: self, queue: centralManagerQueue)
    
    // MARK: - Permissions

    public let authorizationStatus = CurrentValueSubject<BBAuthorization, Never>(.unknown)

    public func authorizationRequest() {
        // Creating the object causes a popup request on iOS 13.1+
        _ = centralManager
    }
    
    // MARK: - Online
    
    public let state = CurrentValueSubject<BBState, Never>(.unknown)

    // MARK: - Devices
    
    public let devices = CurrentValueSubject<[UUID: BBDevice], Never>([:])

    // MARK: - Scanning
    
    public let scanningEnabled = CurrentValueSubject<Bool, Never>(false)
    
    public let scanningResults = PassthroughSubject<BBScanResult, Never>()

    public func scanningStart(serviceUuids: [BBUUID]? = nil) {
        guard !scanningEnabled.value else {
            return
        }

        centralManager.scanForPeripherals(
            withServices: serviceUuids,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
        )
        scanningEnabled.value = true
    }
    
    public func scanningStop() {
        guard scanningEnabled.value else {
            return
        }

        centralManager.stopScan()
        scanningEnabled.value = false
    }
}

extension BBManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 13.1, *) {
            authorizationStatus.value = CBCentralManager.authorization.bleAuthorization
        } else {
            authorizationStatus.value = central.authorization.bleAuthorization
        }
        
        state.value = central.state.bbState

        if scanningEnabled.value && central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil)
        }

        devices.value.values.forEach { device in
            device.centralManagerDidUpdateState(central)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
                
        let device = devices.value[peripheral.identifier] ?? BBDevice(
            centralManager: centralManager,
            peripheral: peripheral
        )
        
        if devices.value[peripheral.identifier] == nil {
            var devices_ = self.devices.value
            devices_[peripheral.identifier] = device
            self.devices.value = devices_
        }

        let scanResult = BBScanResult(device: device, rssi: RSSI.intValue, advertisementData: advertisementData)
        self.scanningResults.send(scanResult)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        devices.value[peripheral.identifier]?.centralManager(central, didConnect: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didFailToConnect: peripheral, error: error)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        devices.value[peripheral.identifier]?.centralManager(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
    }
}

extension BBManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didDiscoverServices: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateValueFor: descriptor, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }
}

extension Array where Element: Any {
    mutating func push(_ element: Self.Element) {
        append(element)
    }

    mutating func popFirst() -> Self.Element? {
        guard let first = first else {
            return nil
        }

        remove(at: 0)
        return first
    }
}
