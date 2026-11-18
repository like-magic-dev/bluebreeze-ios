//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Testing
import Combine

@testable import BlueBreeze

struct BBObservableTests {
    @Test func valueReflectsTheLatestPublishedValue() {
        let observable = BBObservable(0)

        observable.value = 1
        observable.value = 2

        #expect(observable.value == 2)
    }

    @Test func updatesOnlyPublishesNewValues() {
        let observable = BBObservable(0)
        observable.value = 1

        var received: [Int] = []
        let cancellable = observable.updates.sink { received.append($0) }

        observable.value = 2
        observable.value = 3
        cancellable.cancel()

        #expect(received == [2, 3])
    }

    @Test func valuesPublishesTheCurrentValueFirst() {
        let observable = BBObservable(0)
        observable.value = 1

        var received: [Int] = []
        let cancellable = observable.values.sink { received.append($0) }

        observable.value = 2
        cancellable.cancel()

        #expect(received == [1, 2])
    }
}
