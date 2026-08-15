//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
import Combine

/// A single advertisement packet received while scanning, delivered via ``BBManager/scanResults``.
///
/// The same physical device typically produces many ``BBScanResult``s over the course of a scan
/// (one per advertisement packet) -- use ``device`` to get the stable ``BBDevice`` a result
/// belongs to, and ``BBManager/devices`` if you only care about the deduplicated set of
/// peripherals discovered rather than every individual packet.
public struct BBScanResult {
    /// The device this advertisement packet came from.
    public let device: BBDevice

    /// The received signal strength, in dBm. More negative means weaker/farther.
    public let rssi: Int

    /// The raw CoreBluetooth advertisement data for this packet. The computed properties below
    /// decode the common keys; access this directly for anything not already exposed.
    public let advertisementData: [String : Any]

    /// The device's locally-advertised name, if present in this packet, falling back to
    /// ``BBDevice/name`` (i.e. the last name CoreBluetooth reported for this peripheral).
    public var name: String? {
        (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ??
        device.name
    }

    /// Whether the peripheral indicated it accepts connections in this advertisement.
    public var connectable: Bool {
        (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ??
        false
    }

    /// The transmit power level in dBm, if included in the advertisement. Combined with
    /// ``rssi``, can be used to estimate distance to the peripheral.
    public var txPowerLevel: Int? {
        (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
    }

    /// The raw manufacturer-specific data block, if present. The first two bytes are the
    /// little-endian company identifier (see ``manufacturerId``); any remaining bytes are
    /// manufacturer-defined.
    public var manufacturerData: Data? {
        advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }

    /// The Bluetooth SIG-assigned company identifier decoded from ``manufacturerData``, if present.
    public var manufacturerId: UInt16? {
        guard let manufacturerData, manufacturerData.count > 2 else {
            return nil
        }

        return (UInt16(manufacturerData[1]) << 8) | UInt16(manufacturerData[0])
    }

    /// The company name for ``manufacturerId``, looked up from the Bluetooth SIG assigned
    /// numbers database bundled with BlueBreeze. `nil` if there's no manufacturer data or the
    /// identifier isn't recognized.
    public var manufacturerName: String? {
        if let manufacturerId {
            return BBAssignedNumbers.companyIdentifiers[manufacturerId]
        }

        return nil
    }

    /// Service UUIDs advertised in this packet, merged from the primary, overflow, and
    /// solicited service UUID lists.
    public var advertisedServices: [BBUUID] {
        [
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [],
            advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? [],
            advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] ?? []
        ].flatMap { $0 }
    }

    /// Per-service advertisement data, keyed by service UUID, if any was included in the packet.
    public var advertisedServiceData: [BBUUID: Data] {
        advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] ?? [:]
    }

    private let creationTimestamp = Date()

    /// When this advertisement was received. Uses the timestamp CoreBluetooth attaches to the
    /// packet when available, otherwise falls back to when this `BBScanResult` was created.
    public var timestamp: Date {
        if let timestamp = (advertisementData["kCBAdvDataTimestamp"] as? NSNumber)?.doubleValue {
            return Date(timeIntervalSinceReferenceDate: timestamp)
        }

        return creationTimestamp
    }

    /// The primary PHY the advertisement was received on (see `CBManagerPHY` for possible
    /// values), if reported.
    public var rxPrimaryPhi: Int? {
        (advertisementData["kCBAdvDataRxPrimaryPHY"] as? NSNumber)?.intValue
    }

    /// The secondary PHY the advertisement was received on (see `CBManagerPHY` for possible
    /// values), if reported -- only present for Bluetooth 5 extended advertisements.
    public var rxSecondaryPhi: Int? {
        (advertisementData["kCBAdvDataRxSecondaryPHY"] as? NSNumber)?.intValue
    }
}
