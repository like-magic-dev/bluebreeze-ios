//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth
import Combine

public struct BBScanResult {
    public let device: BBDevice
    public let rssi: Int
    public let advertisementData: [String : Any]
    
    public var name: String? {
        device.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
    }
    
    public var connectable: Bool {
        (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
    }
    
    public var txPowerLevel: Int? {
        (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
    }

    public var manufacturerData: Data? {
        advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
        
    public var manufacturerId: Int? {
        guard let manufacturerData, manufacturerData.count > 2 else {
            return nil
        }

        return (Int(manufacturerData[1]) << 8) | Int(manufacturerData[0])
    }
    
    public var manufacturerName: String? {
        if let manufacturerId {
            return BBConstants.manufacturers[manufacturerId]
        }
        
        return nil
    }
    
    public var advertisedServices: [BBUUID] {
        [
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [],
            advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? [],
            advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] ?? []
        ].flatMap { $0 }
    }
    
    public var advertisedServiceData: [BBUUID: Data] {
        advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] ?? [:]
    }
    
    private let creationTimestamp = Date()
    
    public var timestamp: Date {
        if let timestamp = (advertisementData["kCBAdvDataTimestamp"] as? NSNumber)?.doubleValue {
            return Date(timeIntervalSinceReferenceDate: timestamp)
        }
        
        return creationTimestamp
    }
    
    public var rxPrimaryPhi: Int? {
        (advertisementData["kCBAdvDataRxPrimaryPHY"] as? NSNumber)?.intValue
    }
    
    public var rxSecondaryPhi: Int? {
        (advertisementData["kCBAdvDataRxSecondaryPHY"] as? NSNumber)?.intValue
    }
}
