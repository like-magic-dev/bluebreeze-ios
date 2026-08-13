//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Foundation
import CoreBluetooth
import Combine

#if os(iOS) || os(ipadOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The entry point for BlueBreeze: owns the underlying `CBCentralManager`, tracks Bluetooth
/// authorization and power state, and discovers peripherals as ``BBDevice`` instances.
///
/// Create and retain a single `BBManager` for the lifetime of your app (or feature). All of its
/// state is exposed as Combine publishers so your UI can observe it reactively:
/// ```swift
/// let manager = BBManager()
///
/// manager.state
///     .sink { state in
///         if state == .poweredOn {
///             manager.scanStart()
///         }
///     }
///     .store(in: &cancellables)
///
/// manager.scanResults
///     .sink { result in
///         print(result.name ?? "Unknown device", result.rssi)
///     }
///     .store(in: &cancellables)
/// ```
///
/// - Important: All `CBCentralManagerDelegate`/`CBPeripheralDelegate` callbacks (and therefore all
///   publisher updates driven by them) are delivered on a private background queue, not the main
///   thread. Use `.receive(on: DispatchQueue.main)` before updating UI.
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

    /// The app's current Bluetooth authorization status. Publishes an update whenever the user
    /// grants, denies, or changes Bluetooth permission for the app.
    public let authorizationStatus = CurrentValueSubject<BBAuthorization, Never>(.unknown)

    /// Triggers the system Bluetooth permission prompt if authorization is still ``BBAuthorization/unknown``.
    ///
    /// Call this before scanning if you want to prompt the user explicitly rather than have the
    /// prompt appear implicitly on the first ``scanStart(serviceUuids:)`` call.
    public func authorizationRequest() {
        // Creating the object causes a popup request on iOS 13.1+
        _ = centralManager
    }

    /// Opens the system Settings screen where the user can grant Bluetooth permission after
    /// having previously denied it (the in-app prompt cannot be shown again once denied).
    public func authorizationOpenSettings() {
#if os(iOS) || os(ipadOS)
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
#elseif os(macOS)
        if let settingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth") {
            NSWorkspace.shared.open(settingsUrl)
        }
#endif
    }

    // MARK: - Capabilities

    /// Whether this device supports Bluetooth 5 extended scanning and connecting (longer range,
    /// higher throughput, and more advertisement data than legacy Bluetooth 4.x).
    public var supportsExtended: Bool {
#if os(iOS) || os(watchOS) || os(ipadOS)
        // Dynamic check for extended scan capability
        CBCentralManager.supports(.extendedScanAndConnect)
#elseif os(macOS)
        // Always supported
        true
#else
        // Unknown platform
        false
#endif
    }

    // MARK: - Online

    /// The current power/availability state of the device's Bluetooth adapter.
    public let state = CurrentValueSubject<BBState, Never>(.unknown)

    // MARK: - Devices

    /// All peripherals discovered so far (during this scan or a previous one), keyed by their
    /// system-assigned identifier. Entries are added as they're discovered and are never removed
    /// automatically, so a device that goes out of range remains here with its last known state.
    public let devices = CurrentValueSubject<[UUID: BBDevice], Never>([:])

    // MARK: - Scan

    /// Whether a scan is currently in progress. Reflects the state requested via
    /// ``scanStart(serviceUuids:)``/``scanStop()``, not just whether the adapter is powered on --
    /// if the adapter powers back on while this is `true`, scanning resumes automatically.
    public let scanEnabled = CurrentValueSubject<Bool, Never>(false)

    // Remembers the filter passed to scanStart so it is reused on BT power cycles
    private var scanServiceUuids: [BBUUID]?

    /// Fires once for every advertisement packet received while scanning, including repeated
    /// packets from the same device -- this is not a "new device discovered" event. Use
    /// ``BBScanResult/device`` to access the corresponding stable ``BBDevice``, and ``devices``
    /// if you only need the deduplicated set of discovered peripherals.
    public let scanResults = PassthroughSubject<BBScanResult, Never>()

    /// Starts scanning for nearby peripherals. Does nothing if a scan is already in progress.
    ///
    /// If the adapter isn't powered on yet, the request is remembered and the scan starts
    /// automatically once it is.
    ///
    /// - Parameter serviceUuids: Restricts results to peripherals advertising at least one of
    ///   these service UUIDs. Pass `nil` (the default) to discover all nearby peripherals --
    ///   note that iOS requires an explicit list while the app is backgrounded.
    public func scanStart(serviceUuids: [BBUUID]? = nil) {
        guard !scanEnabled.value else {
            return
        }

        centralManager.scanForPeripherals(
            withServices: serviceUuids,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
        )

        scanServiceUuids = serviceUuids
        scanEnabled.value = true
    }

    /// Stops an in-progress scan. Does nothing if no scan is in progress.
    public func scanStop() {
        guard scanEnabled.value else {
            return
        }

        centralManager.stopScan()

        scanEnabled.value = false
        scanServiceUuids = nil
    }
}

// MARK: - CoreBluetooth delegate plumbing
//
// The methods below are `public` only because CBCentralManagerDelegate/CBPeripheralDelegate
// require it; they are called by CoreBluetooth, not meant to be called directly, and simply
// route each callback to the BBDevice it concerns.

extension BBManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 13.1, *) {
            authorizationStatus.value = CBCentralManager.authorization.bleAuthorization
        } else {
            authorizationStatus.value = central.authorization.bleAuthorization
        }

        state.value = central.state.bbState

        if scanEnabled.value && central.state == .poweredOn {
            centralManager.scanForPeripherals(
                withServices: scanServiceUuids,
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: true
                ])
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
        self.scanResults.send(scanResult)
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

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        devices.value[peripheral.identifier]?.peripheral(peripheral, didWriteValueFor: descriptor, error: error)
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
