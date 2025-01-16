//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import CoreBluetooth

public enum BBAuthorization {
    case unknown
    case denied
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
