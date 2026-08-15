//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The subset of `CBDescriptor` that BlueBreeze depends on.
/// Makes BlueBreeze public classes independent of CoreBluetooth data structures. 

protocol CBDescriptorProtocol: AnyObject {
    var characteristic_: CBCharacteristicProtocol? { get }
}

extension CBDescriptor: CBDescriptorProtocol {
    var characteristic_: CBCharacteristicProtocol? {
        characteristic
    }
}
