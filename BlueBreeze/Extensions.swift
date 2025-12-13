//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Combine

extension CurrentValueSubject where Failure == Never {
    public var updates: AnyPublisher<Output, Never> {
        get {
            return self.dropFirst().eraseToAnyPublisher()
        }
    }
}
