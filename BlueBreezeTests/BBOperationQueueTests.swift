//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Testing
import CoreBluetooth
@testable import BlueBreeze

/// A minimal operation used to drive `BBOperationQueue` directly, without needing any of the
/// real operations' CoreBluetooth-specific logic.
private final class TestOperation: BBOperation<Void> {
    private(set) var executeCallCount = 0
    var onExecute: (() -> Void)?
    var customTimeOut: TimeInterval = 5

    override func execute(_ centralManager: CBCentralManagerProtocol) {
        executeCallCount += 1
        onExecute?()
    }

    override var timeOut: TimeInterval {
        customTimeOut
    }

    // Repurposed as a manually-triggerable completion hook -- unlike calling `completeSuccess`
    // directly, going through `BBOperationQueue.centralManager(_:didConnect:)` also makes the
    // queue check whether the next operation can now start.
    override func centralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol) {
        completeSuccess(())
    }
}

struct BBOperationQueueTests {
    @Test func operationsRunOneAtATimeInOrder() async throws {
        let queue = BBOperationQueue(centralManager: MockCBCentralManager())

        let first = TestOperation(peripheral: MockCBPeripheral())
        let second = TestOperation(peripheral: MockCBPeripheral())
        second.onExecute = { second.completeSuccess(()) }

        async let firstResult: Void = queue.operationEnqueue(first)

        // Give the first operation's enqueue a chance to actually run before enqueueing the second.
        try await Task.sleep(nanoseconds: 20_000_000)
        #expect(first.executeCallCount == 1)

        async let secondResult: Void = queue.operationEnqueue(second)
        try await Task.sleep(nanoseconds: 20_000_000)

        // The second operation must not start until the first completes.
        #expect(second.executeCallCount == 0)

        // Complete `first` through the queue (not directly) so it also re-checks whether the
        // next operation can now start -- mirroring how real completion always flows through one
        // of BBOperationQueue's forwarding methods.
        queue.centralManager(MockCBCentralManager(), didConnect: MockCBPeripheral())

        _ = try await (firstResult, secondResult)
        #expect(second.executeCallCount == 1)
    }

    @Test func anOperationThatNeverCompletesTimesOutAndAdvancesTheQueue() async throws {
        let queue = BBOperationQueue(centralManager: MockCBCentralManager())

        let first = TestOperation(peripheral: MockCBPeripheral())
        first.customTimeOut = 0.05

        let second = TestOperation(peripheral: MockCBPeripheral())
        second.onExecute = { second.completeSuccess(()) }

        async let firstResult: Void = queue.operationEnqueue(first)
        async let secondResult: Void = queue.operationEnqueue(second)

        do {
            try await firstResult
            Issue.record("Expected the timed-out operation to throw")
        } catch is BBError {
            // Expected: the operation was cancelled after timing out.
        }

        try await secondResult
        #expect(second.executeCallCount == 1)
    }

    @Test func operationCompletingSynchronouslyLetsTheNextOneStartImmediately() async throws {
        let queue = BBOperationQueue(centralManager: MockCBCentralManager())

        let first = TestOperation(peripheral: MockCBPeripheral())
        first.onExecute = { first.completeSuccess(()) }

        let second = TestOperation(peripheral: MockCBPeripheral())
        second.onExecute = { second.completeSuccess(()) }

        try await queue.operationEnqueue(first)
        try await queue.operationEnqueue(second)

        #expect(first.executeCallCount == 1)
        #expect(second.executeCallCount == 1)
    }
}
