//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
@testable import BlueBreeze

final class MockCBCharacteristic: CBCharacteristicProtocol {
    init(
        uuid: CBUUID = CBUUID(string: "18C40001-0000-0000-0000-000000000000"),
        value: Data? = nil,
        properties: CBCharacteristicProperties = [],
        isNotifying: Bool = false
    ) {
        self.uuid = uuid
        self.value = value
        self.properties = properties
        self.isNotifying = isNotifying
    }

    let uuid: CBUUID
    var value: Data?
    var properties: CBCharacteristicProperties
    var isNotifying: Bool
}
