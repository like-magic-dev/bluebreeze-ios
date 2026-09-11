//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// A single discovered service of a ``BBDevice``, populated by ``BBDevice/discoverServices()`` and
/// exposed via ``BBDevice/services``.
public struct BBService {
    /// This service's Bluetooth UUID.
    public let uuid: BBUUID

    /// The characteristics discovered for this service so far. Empty until ``BBDevice/discoverServices()``
    /// has completed.
    public let characteristics: [BBCharacteristic]

    /// The service's human-readable name, if ``uuid`` is a Bluetooth SIG-assigned service UUID.
    public var name: String? {
        BBAssignedNumbers.serviceUUIDs[uuid]
    }
}
