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
  connection status, characteristic data, ...) is a `BBObservable`: read its current `value`,
  subscribe to its `values` publisher (the current value, then new ones), or only to its
  `updates`.
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
    .package(url: "https://github.com/like-magic-dev/bluebreeze-ios.git", from: "1.1.0"),
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
manager.state.values
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

    for service in device.services.value {
        for characteristic in service.characteristics where characteristic.properties.contains(.read) {
            let data = try await characteristic.read()
            print(characteristic.uuid, data ?? Data())
        }
    }

    try await device.disconnect()
}
```

### Observing state

Every piece of state is a `BBObservable`, which you can query in three ways:

```swift
characteristic.data.value                      // the current value
characteristic.data.values.sink { data in }    // the current value, then new values
characteristic.data.updates.sink { data in }   // only values that arrive from now on
```

For example, to receive notifications:

```swift
characteristic.data.updates
    .sink { data in
        print(characteristic.uuid, data ?? Data())
    }
    .store(in: &cancellables)
try await characteristic.subscribe()
```

See [`BlueBreezeExample`](BlueBreezeExample) for a full SwiftUI app built on top of BlueBreeze, and
[`ARCHITECTURE.md`](ARCHITECTURE.md) for how scanning, connecting, and the operation queue fit
together.

## Background updates

iOS suspends your app shortly after it leaves the foreground. To keep receiving data in the background, 
add the `bluetooth-central` background mode to your app's `Info.plist`, or enable **Uses Bluetooth LE
accessories** under **Signing & Capabilities → Background Modes** in Xcode:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

With it, iOS notifies your app whenever a connected peripheral sends a notification, connects or
disconnects, so BlueBreeze's publishers and `async` operations keep working. 

Even so, there are limits:
- **Keep background work short.** Each wake-up only gives your app a few seconds of execution
  time before it's suspended again. For longer work, wrap it in
  `UIApplication.beginBackgroundTask(withName:expirationHandler:)`.
- **Scanning in the background needs service UUIDs.** Pass `serviceUuids` to `scanStart`: a scan
  with `nil` finds nothing while the app is in the background. iOS also skips duplicate advertisements 
  and scans less often, so expect fewer `scanResults` and slower discovery.
- **Reconnecting can time out.** `connect()` times out after 5 seconds like every other
  operation, so it can't wait indefinitely for a device to come back in range. Watch
  `connectionStatus` and retry `connect()` when you expect the device to be reachable again.
- **No relaunch after termination.** BlueBreeze doesn't support CoreBluetooth state preservation
  and restoration. If iOS terminates your app in the background (e.g. under memory pressure),
  connections are dropped and the app isn't relaunched for Bluetooth events. Apps the user
  force-quits from the app switcher are never relaunched for Bluetooth, with or without
  restoration.

## Documentation

The public API is fully documented with DocC. Generate and view it locally with:

```bash
swift package generate-documentation --target BlueBreeze
swift package --disable-sandbox preview-documentation --target BlueBreeze
```

Or browse it in Xcode via **Product > Build Documentation**.

## License

BlueBreeze is available under the MIT license. See [LICENSE](LICENSE) for details.
