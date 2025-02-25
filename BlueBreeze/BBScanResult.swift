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
    
    public var id: UUID {
        get {
            return device.id
        }
    }
    
    public var name: String? {
        get {
            return device.name ??
                (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        }
    }
    
    public var connectable: Bool {
        get {
            return (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
        }
    }
    
    public var txPowerLevel: Int? {
        get {
            return (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        }
    }

    
    public var manufacturerData: Data? {
        get {
            return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        }
    }
        
    public var manufacturerId: Int? {
        get {
            guard let manufacturerData, manufacturerData.count > 2 else {
                return nil
            }

            return (Int(manufacturerData[1]) << 8) | Int(manufacturerData[0])
        }
    }
    
    public var manufacturerName: String? {
        get {
            if let manufacturerId {
                return BBConstants.manufacturers[manufacturerId]
            }
            
            return nil
        }
    }
    
    public var advertisedServices: [BBUUID] {
        get {
            return [
                advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [],
                advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? [],
                advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] ?? []
            ].flatMap { $0 }
        }
    }
    
    public var advertisedServiceData: [BBUUID: Data] {
        get {
            return advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] ?? [:]
        }
    }
}
