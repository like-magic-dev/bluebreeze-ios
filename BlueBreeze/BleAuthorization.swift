import CoreBluetooth

public enum BleAuthorization {
    case unknown
    case denied
    case authorized
}

extension CBManagerAuthorization {
    var bleAuthorization: BleAuthorization {
        switch self {
        case .notDetermined: return .unknown
        case .restricted: return .denied
        case .denied: return .denied
        case .allowedAlways: return .authorized
        @unknown default: return .unknown
        }
    }
}
