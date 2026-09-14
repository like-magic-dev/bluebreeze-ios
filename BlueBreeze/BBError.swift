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
        BBError(message: "Unknown error")
    }

    /// Thrown to any operation still queued or in flight when it's cancelled
    public static var operationCancelled: BBError {
        BBError(message: "Operation cancelled")
    }

    /// Thrown by an operation when its owning ``BBDevice`` is not available
    public static var deviceUnavailable: BBError {
        BBError(message: "Device is no longer available")
    }

    /// Thrown to any operation executing when Bluetooth stops being powered on mid-operation.
    public static func notPoweredOn(_ state: BBState) -> BBError {
        BBError(message: "Bluetooth is no longer powered on (state: \(state))")
    }

    /// Thrown when CoreBluetooth reports that the connection attempt failed
    public static func connectFailed(_ error: Error?) -> BBError {
        BBError(message: error?.localizedDescription ?? "Connection failed")
    }
}
