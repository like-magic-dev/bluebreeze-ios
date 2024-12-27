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
