//
//  Extensions.swift
//  BlueBreeze
//
//  Created by Alessandro Mulloni on 24.12.24.
//

import CoreBluetooth

extension CBUUID {
    var uuid: UUID {
        get {
            return self.data.withUnsafeBytes {
                (pointer: UnsafeRawBufferPointer) -> UUID in
                let uuid = pointer.load(as: uuid_t.self)
                return UUID(uuid: uuid)
            }
        }
    }
}

extension UUID {
    init(shortString: String) {
        self.init(uuidString: "0000\(shortString)-0000-1000-8000-00805F9B34FB")!
    }
}

func ==(a: UUID, b: CBUUID) -> Bool {
    return a.uuidString == b.uuidString
}

func ==(a: CBUUID, b: UUID) -> Bool {
    return a.uuidString == b.uuidString
}
