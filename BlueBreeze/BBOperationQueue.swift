/// Protocol to enqueue an operation and transform it into an async-awaitable result

protocol BBOperationQueue: AnyObject {
    // MARK: - Enqueue an operation -- allows awaiting for the result asynchronously
    func enqueueOperation<RESULT, OP: BBOperation>(_ operation: OP) async throws -> RESULT where OP.RESULT == RESULT
}