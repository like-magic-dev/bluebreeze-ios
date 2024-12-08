/// Protocol to enqueue an operation and transform it into an async-awaitable result

protocol BleOperationQueue: AnyObject {
    // MARK: - Enqueue an operation -- allows awaiting for the result asynchronously
    func enqueueOperation<RESULT, OP: BleOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT
}
