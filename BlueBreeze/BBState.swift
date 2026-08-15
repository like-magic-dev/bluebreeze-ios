//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The power/availability state of the device's Bluetooth adapter, mirroring `CBManagerState`.
public enum BBState {
    /// The state hasn't been determined yet -- typically the initial value before CoreBluetooth
    /// reports a state.
    case unknown

    /// The adapter is temporarily resetting; connections and scans are dropped and will need to
    /// be restarted once it settles into another state.
    case resetting

    /// This device doesn't support Bluetooth Low Energy.
    case unsupported

    /// The app isn't authorized to use Bluetooth. See ``BBAuthorization``.
    case unauthorized

    /// Bluetooth is turned off. Scanning and connecting are unavailable until it's powered on.
    case poweredOff

    /// Bluetooth is turned on and available for scanning and connecting.
    case poweredOn
}

extension CBManagerState {
    var bbState: BBState {
        switch self {
        case .unknown: return .unknown
        case .resetting: return .resetting
        case .unsupported: return .unsupported
        case .unauthorized: return .unauthorized
        case .poweredOff: return .poweredOff
        case .poweredOn: return .poweredOn
        @unknown default: return .unknown
        }
    }
}
