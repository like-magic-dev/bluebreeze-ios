//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The subset of `CBCharacteristic` that BlueBreeze depends on.
/// Makes BlueBreeze public classes independent of CoreBluetooth data structures. 

protocol CBCharacteristicProtocol: AnyObject {
    var uuid: CBUUID { get }
    var value: Data? { get }
    var properties: CBCharacteristicProperties { get }
    var isNotifying: Bool { get }
}

extension CBCharacteristic: CBCharacteristicProtocol { }
