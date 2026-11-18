//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine

/// An observable value, used for every piece of state BlueBreeze exposes (``BBManager/state``,
/// ``BBDevice/connectionStatus``, ``BBCharacteristic/data``, and so on).
///
/// ```swift
/// characteristic.data.value                // the current value
/// characteristic.data.values.sink { }      // the current value, then new values
/// characteristic.data.updates.sink { }     // only new values
/// ```
public final class BBObservable<Value> {
    private let subject: CurrentValueSubject<Value, Never>

    /// A stream of the current ``value``, followed by every value published from now on.
    public let values: AnyPublisher<Value, Never>

    /// A stream of only the values published from now on, without the current ``value``.
    public let updates: AnyPublisher<Value, Never>

    init(_ value: Value) {
        let subject = CurrentValueSubject<Value, Never>(value)
        self.subject = subject
        self.values = subject.eraseToAnyPublisher()
        self.updates = subject.dropFirst().eraseToAnyPublisher()
    }

    /// The current value.
    public internal(set) var value: Value {
        get {
            return subject.value
        }
        set {
            subject.value = newValue
        }
    }
}
