# BlueBreeze iOS

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/cocoapods/v/BlueBreeze.svg)](https://cocoapods.org/pods/BlueBreeze)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS-lightgrey.svg)](Package.swift)

BlueBreeze is a modern Bluetooth LE library for iOS, macOS, and watchOS, built on Combine for all
data streams. It wraps CoreBluetooth's callback-based API with `async`/`await` operations and
serial per-device request queuing, so you don't have to hand-write connection state machines or
worry about overlapping BLE requests.

- **Combine-first** -- every piece of state (adapter power, authorization, discovered devices,
  connection status, characteristic data, ...) is a `CurrentValueSubject` or `PassthroughSubject`
  you can observe reactively.
- **`async`/`await` operations** -- connect, discover services, read, write, and
  subscribe/unsubscribe are all `async throws` calls with a built-in 5 second timeout, instead of
  delegate callbacks you have to correlate yourself.
- **Automatic per-device request queuing** -- operations on the same device are serialized in call
  order; you can fire off several `await`s without worrying about CoreBluetooth's "one request at
  a time" limitations.
- **Bluetooth SIG assigned numbers built in** -- known company IDs, service UUIDs, and
  characteristic UUIDs are bundled and looked up for you (see `Tools/fetch_known_uuids.py`).

## Installation

### Swift Package Manager

Add BlueBreeze as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/like-magic-dev/bluebreeze-ios.git", from: "1.0.0"),
]
```

Or, in Xcode: **File > Add Package Dependencies...** and enter the repository URL above.

### CocoaPods

```ruby
pod 'BlueBreeze'
```

## Requirements

- iOS 13+, macOS 10.15+, or watchOS 6+
- Swift 5.6+ (to build the package; DocC generation requires this via `swift-docc-plugin`)
- Add `NSBluetoothAlwaysUsageDescription` to your app's `Info.plist` (required by iOS for any app
  that uses Bluetooth)

## Quick start

```swift
import BlueBreeze
import Combine

let manager = BBManager()
var cancellables = Set<AnyCancellable>()

// Observe adapter state and start scanning once it's ready
manager.state
    .sink { state in
        if state == .poweredOn {
            manager.scanStart()
        }
    }
    .store(in: &cancellables)

// Observe scan results
manager.scanResults
    .sink { result in
        print(result.name ?? "Unknown device", result.rssi)
    }
    .store(in: &cancellables)

// Connect, discover, and talk to a device
Task {
    guard let device = manager.devices.value.values.first else { return }

    try await device.connect()
    try await device.discoverServices()

    for (_, characteristics) in device.services.value {
        for characteristic in characteristics where characteristic.properties.contains(.read) {
            let data = try await characteristic.read()
            print(characteristic.id, data ?? Data())
        }
    }

    try await device.disconnect()
}
```

See [`BlueBreezeExample`](BlueBreezeExample) for a full SwiftUI app built on top of BlueBreeze, and
[`ARCHITECTURE.md`](ARCHITECTURE.md) for how scanning, connecting, and the operation queue fit
together.

## Documentation

The public API is fully documented with DocC. Generate and view it locally with:

```bash
swift package generate-documentation --target BlueBreeze
swift package --disable-sandbox preview-documentation --target BlueBreeze
```

Or browse it in Xcode via **Product > Build Documentation**.

## License

BlueBreeze is available under the MIT license. See [LICENSE](LICENSE) for details.
