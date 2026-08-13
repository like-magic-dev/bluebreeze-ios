//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

/// The app's authorization to use Bluetooth, mirroring `CBManagerAuthorization`.
public enum BBAuthorization {
    /// The user hasn't been asked yet. Call ``BBManager/authorizationRequest()`` (or start a
    /// scan) to trigger the system permission prompt.
    case unknown

    /// The user denied permission, or it's restricted by policy (e.g. parental controls). Direct
    /// the user to ``BBManager/authorizationOpenSettings()`` to change it.
    case denied

    /// The app is authorized to use Bluetooth.
    case authorized
}

extension CBManagerAuthorization {
    var bleAuthorization: BBAuthorization {
        switch self {
        case .notDetermined: return .unknown
        case .restricted: return .denied
        case .denied: return .denied
        case .allowedAlways: return .authorized
        @unknown default: return .unknown
        }
    }
}
