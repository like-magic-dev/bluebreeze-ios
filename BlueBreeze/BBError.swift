//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Foundation

/// The error type thrown by BlueBreeze's async APIs (connect, disconnect, read, write,
/// subscribe/unsubscribe, discover services, negotiate MTU, ...) on failure, cancellation, or
/// timeout (operations time out after 5 seconds if the peripheral never responds).
public struct BBError: Error {
    /// A human-readable description of what went wrong. Not currently structured for
    /// programmatic matching -- catch `BBError` to distinguish BlueBreeze errors from other
    /// `Error`s, and use `message` for logging/display rather than branching on its contents.
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

extension BBError {
    /// A generic fallback used where CoreBluetooth reports failure without a more specific error.
    public static var unknown: BBError {
        get {
            return BBError(message: "Unknown error")
        }
    }
}
