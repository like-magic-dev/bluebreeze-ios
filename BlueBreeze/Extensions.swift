//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine

extension CurrentValueSubject where Failure == Never {
    /// This subject's publisher without its current value replayed on subscription -- only
    /// future updates. Useful when you want to react to *changes* (e.g. show a one-off alert on
    /// disconnect) without also firing for whatever the value already happened to be.
    public var updates: AnyPublisher<Output, Never> {
        get {
            return self.dropFirst().eraseToAnyPublisher()
        }
    }
}
