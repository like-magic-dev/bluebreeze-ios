//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The subset of `CBService` that BlueBreeze depends on.
/// Makes BlueBreeze public classes independent of CoreBluetooth data structures.

protocol CBServiceProtocol: AnyObject {
    var uuid: CBUUID { get }
    var characteristics_: [CBCharacteristicProtocol]? { get }
}

extension CBService: CBServiceProtocol {
    var characteristics_: [CBCharacteristicProtocol]? {
        characteristics
    }
}
