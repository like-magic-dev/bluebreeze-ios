//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// Operation supported by a ``BBCharacteristic``, as reported by the peripheral. See
/// ``BBCharacteristic/properties``.
public enum BBCharacteristicProperty {
    /// Supports ``BBCharacteristic/read()``.
    case read

    /// Supports ``BBCharacteristic/write(_:withResponse:)`` with `withResponse: true`
    /// (acknowledged writes).
    case writeWithResponse

    /// Supports ``BBCharacteristic/write(_:withResponse:)`` with `withResponse: false`
    /// (unacknowledged writes).
    case writeWithoutResponse

    /// Supports ``BBCharacteristic/subscribe()``/``BBCharacteristic/unsubscribe()``.
    /// Covers both notify and indicate.
    case notify
}
