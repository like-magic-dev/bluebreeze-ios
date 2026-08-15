//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Testing
import CoreBluetooth
import Combine

@preconcurrency @testable import BlueBreeze

struct BBDeviceTests {
    @Test func connectSucceeds() async throws {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        let device = BBDevice(centralManager: central, peripheral: peripheral)

        // Simulate CoreBluetooth completing the connection synchronously, as if it had already
        // happened by the time `connect(_:)` returns.
        central.onConnect = { connectedPeripheral in
            device.centralManager(central, didConnect: connectedPeripheral)
        }

        try await device.connect()

        #expect(device.connectionStatus.value == .connected)
        #expect(central.connectedPeripherals.count == 1)
    }

    @Test func connectFailsWhenCoreBluetoothReportsFailure() async throws {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        let device = BBDevice(centralManager: central, peripheral: peripheral)

        central.onConnect = { connectedPeripheral in
            device.centralManager(central, didFailToConnect: connectedPeripheral, error: BBError(message: "nope"))
        }

        await #expect(throws: BBError.self) {
            try await device.connect()
        }

        #expect(device.connectionStatus.value == .disconnected)
    }

    @Test func disconnectSucceeds() async throws {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        let device = BBDevice(centralManager: central, peripheral: peripheral)

        central.onCancelPeripheralConnection = { disconnectedPeripheral in
            device.centralManager(central, didDisconnectPeripheral: disconnectedPeripheral, error: nil)
        }

        try await device.disconnect()

        #expect(device.connectionStatus.value == .disconnected)
        #expect(central.cancelledPeripherals.count == 1)
    }

    @Test func discoverServicesPopulatesServicesAndCharacteristics() async throws {
        let characteristic = MockCBCharacteristic(uuid: CBUUID(string: "AAAA"))
        let service = MockCBService(uuid: CBUUID(string: "BBBB"), characteristics_: [characteristic])

        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        peripheral.services_ = [service]

        let device = BBDevice(centralManager: central, peripheral: peripheral)

        peripheral.onDiscoverServices = {
            device.peripheral(peripheral, didDiscoverServices: nil)
        }
        // Deferred to the next run loop turn, like a real CoreBluetooth callback: the discovery
        // handler that triggers this is itself invoked from within BBOperationQueue's lock, and
        // that lock isn't reentrant -- firing this synchronously would deadlock.
        peripheral.onDiscoverCharacteristics = { discoveredService in
            DispatchQueue.main.async {
                device.peripheral(peripheral, didDiscoverCharacteristicsFor: discoveredService, error: nil)
            }
        }

        try await device.discoverServices()

        let discoveredCharacteristics = try #require(device.services.value[service.uuid])
        #expect(discoveredCharacteristics.count == 1)
        #expect(discoveredCharacteristics.first?.id == characteristic.uuid)
        #expect(peripheral.discoverCharacteristicsCalls.count == 1)
    }

    @Test func discoverServicesCompletesImmediatelyWhenThereAreNoServices() async throws {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        peripheral.services_ = []

        let device = BBDevice(centralManager: central, peripheral: peripheral)

        peripheral.onDiscoverServices = {
            device.peripheral(peripheral, didDiscoverServices: nil)
        }

        try await device.discoverServices()

        #expect(device.services.value.isEmpty)
        #expect(peripheral.discoverCharacteristicsCalls.isEmpty)
    }

    @Test func negotiateMTUUpdatesMTUFromMaximumWriteValueLength() async throws {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        peripheral.maximumWriteValueLengthWithResponse = 100
        peripheral.maximumWriteValueLengthWithoutResponse = 50

        let device = BBDevice(centralManager: central, peripheral: peripheral)

        try await device.negotiateMTU()

        // The smaller of the two write-length limits, plus the 3-byte ATT header.
        #expect(device.mtu.value == 53)
    }

    @Test func poweringOffResetsServicesAndConnectionStatus() {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        let device = BBDevice(centralManager: central, peripheral: peripheral)

        device.connectionStatus.value = .connected

        central.state = .poweredOff
        device.centralManagerDidUpdateState(central)

        #expect(device.connectionStatus.value == .disconnected)
        #expect(device.services.value.isEmpty)
    }
}
