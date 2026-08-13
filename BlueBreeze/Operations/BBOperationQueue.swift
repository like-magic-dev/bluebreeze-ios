//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// Protocol to enqueue an operation and transform it into an async-awaitable result

protocol BBOperationQueue: AnyObject {
    // MARK: - Enqueue an operation -- allows awaiting for the result asynchronously
    func operationEnqueue<RESULT, OP: BBOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT
}
