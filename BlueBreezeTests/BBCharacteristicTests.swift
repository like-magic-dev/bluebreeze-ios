//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Testing
import CoreBluetooth
import Combine

@testable import BlueBreeze

struct BBCharacteristicTests {
    @Test func readReturnsTheOperationsResult() async throws {
        let queue = MockBBOperationQueue()
        let expectedData = Data([1, 2, 3])
        queue.resultToReturn = expectedData

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: MockCBCharacteristic(),
            operationQueue: queue
        )

        let result = try await characteristic.read()

        #expect(result == expectedData)
        #expect(queue.enqueuedOperations.count == 1)
        #expect(queue.enqueuedOperations.first is BBOperationRead)
    }

    @Test func writeDefaultsToWithResponse() async throws {
        let queue = MockBBOperationQueue()

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: MockCBCharacteristic(),
            operationQueue: queue
        )

        try await characteristic.write(Data([1, 2, 3]))

        let operation = try #require(queue.enqueuedOperations.first as? BBOperationWrite)
        #expect(operation.withResponse == true)
    }

    @Test func writeWithoutResponse() async throws {
        let queue = MockBBOperationQueue()

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: MockCBCharacteristic(),
            operationQueue: queue
        )

        try await characteristic.write(Data([1, 2, 3]), withResponse: false)

        let operation = try #require(queue.enqueuedOperations.first as? BBOperationWrite)
        #expect(operation.withResponse == false)
    }

    @Test func subscribeEnablesNotifications() async throws {
        let queue = MockBBOperationQueue()

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: MockCBCharacteristic(),
            operationQueue: queue
        )

        try await characteristic.subscribe()

        let operation = try #require(queue.enqueuedOperations.first as? BBOperationNotifications)
        #expect(operation.enabled == true)
    }

    @Test func unsubscribeDisablesNotifications() async throws {
        let queue = MockBBOperationQueue()

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: MockCBCharacteristic(),
            operationQueue: queue
        )

        try await characteristic.unsubscribe()

        let operation = try #require(queue.enqueuedOperations.first as? BBOperationNotifications)
        #expect(operation.enabled == false)
    }

    @Test func operationsThrowWhenTheOwningDeviceIsNoLongerAvailable() async throws {
        var queue: MockBBOperationQueue? = MockBBOperationQueue()

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: MockCBCharacteristic(),
            operationQueue: queue
        )

        // The characteristic only holds a weak reference to its operation queue -- dropping the
        // only strong reference simulates the owning BBDevice having been deallocated.
        queue = nil

        await #expect(throws: BBError.self) {
            try await characteristic.read()
        }
    }

    @Test func propertiesMapFromCoreBluetoothCharacteristicProperties() {
        let mockCharacteristic = MockCBCharacteristic(
            properties: [.read, .write, .writeWithoutResponse, .notify]
        )

        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: mockCharacteristic,
            operationQueue: nil
        )

        #expect(characteristic.properties == [.read, .writeWithResponse, .writeWithoutResponse, .notify])
    }

    @Test func didUpdateValueForUpdatesData() {
        let mockCharacteristic = MockCBCharacteristic()
        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: mockCharacteristic,
            operationQueue: nil
        )

        mockCharacteristic.value = Data([9, 9, 9])
        characteristic.peripheral(MockCBPeripheral(), didUpdateValueFor: mockCharacteristic, error: nil)

        #expect(characteristic.data.value == Data([9, 9, 9]))
    }

    @Test func didUpdateNotificationStateForUpdatesIsNotifying() {
        let mockCharacteristic = MockCBCharacteristic(isNotifying: true)
        let characteristic = BBCharacteristic(
            peripheral: MockCBPeripheral(),
            characteristic: mockCharacteristic,
            operationQueue: nil
        )

        characteristic.peripheral(MockCBPeripheral(), didUpdateNotificationStateFor: mockCharacteristic, error: nil)

        #expect(characteristic.isNotifying.value == true)
    }
}
