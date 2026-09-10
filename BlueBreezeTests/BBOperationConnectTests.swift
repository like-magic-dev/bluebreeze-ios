//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Testing
import CoreBluetooth
@testable import BlueBreeze

/// A `BBOperationConnect` with a short timeout, so the timed-out-connect path can be exercised
/// without waiting the real 5 seconds.
private final class FastConnectOperation: BBOperationConnect {
    override var timeOut: TimeInterval { 0.05 }
}

struct BBOperationConnectTests {
    @Test func cancelTearsDownAPendingConnection() async throws {
        let central = MockCBCentralManager()
        let peripheral = MockCBPeripheral()
        let operation = BBOperationConnect(peripheral: peripheral)

        // Simulate a connect that never resolves: `execute` starts it, then `cancel()` fires
        // (as the queue's timeout closure would) before any `didConnect`.
        await #expect(throws: BBError.self) {
            try await withCheckedThrowingContinuation { (continuation: BBContinuation<Void>) in
                operation.continuation = continuation
                operation.execute(central)
                operation.cancel(central)
            }
        }

        #expect(central.connectedPeripherals.count == 1)
        #expect(central.cancelledPeripherals.count == 1)
    }

    @Test func timedOutConnectCancelsThePendingConnectionThroughTheQueue() async throws {
        let central = MockCBCentralManager()
        let queue = BBOperationQueue(centralManager: central)
        let peripheral = MockCBPeripheral()

        // No `onConnect` hook, so CoreBluetooth never reports the connection -- the operation
        // runs into its timeout.
        await #expect(throws: BBError.self) {
            try await queue.operationEnqueue(FastConnectOperation(peripheral: peripheral))
        }

        #expect(central.cancelledPeripherals.count == 1)
    }
}
