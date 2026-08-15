//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
@testable import BlueBreeze

final class MockCBDescriptor: CBDescriptorProtocol {
    init(characteristic_: CBCharacteristicProtocol? = nil) {
        self.characteristic_ = characteristic_
    }

    var characteristic_: CBCharacteristicProtocol?
}
