//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

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
