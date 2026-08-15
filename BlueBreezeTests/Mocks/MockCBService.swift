//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
@testable import BlueBreeze

final class MockCBService: CBServiceProtocol {
    init(
        uuid: CBUUID = CBUUID(string: "18C40002-0000-0000-0000-000000000000"),
        characteristics_: [CBCharacteristicProtocol]? = nil
    ) {
        self.uuid = uuid
        self.characteristics_ = characteristics_
    }

    let uuid: CBUUID
    var characteristics_: [CBCharacteristicProtocol]?
}
