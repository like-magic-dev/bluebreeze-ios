//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import Foundation

public struct BBError: Error {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

extension BBError {
    public static var unknown: BBError {
        get {
            return BBError(message: "Unknown error")
        }
    }
}
