import Foundation

struct BBError: Error {
    let message: String
}

extension BBError {
    static var unknown: BBError {
        get {
            return BBError(message: "Unknown error")
        }
    }
}
