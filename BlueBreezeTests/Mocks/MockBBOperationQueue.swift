//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

@testable import BlueBreeze

/// A `BBOperationQueueProtocol` mock that resolves every enqueued operation immediately, without
/// any real queueing/timeout machinery or CoreBluetooth involvement. Lets `BBCharacteristic` be
/// tested in isolation: configure `resultToReturn`/`errorToThrow`, then inspect
/// `enqueuedOperations` for what was requested.
final class MockBBOperationQueue: BBOperationQueueProtocol {
    private(set) var enqueuedOperations: [Any] = []

    var errorToThrow: Error?
    var resultToReturn: Any = ()

    func operationEnqueue<RESULT, OP: BBOperationProtocol>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT {
        enqueuedOperations.append(operation)

        if let errorToThrow {
            throw errorToThrow
        }

        guard let result = resultToReturn as? RESULT else {
            fatalError("MockBBOperationQueue: resultToReturn (\(type(of: resultToReturn))) does not match the expected result type (\(RESULT.self))")
        }

        return result
    }
}
