// swift-tools-version:5.6

//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import PackageDescription

let package = Package(
    name: "BlueBreeze",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "BlueBreeze", targets: ["BlueBreeze"]),
    ],
    dependencies: [
        // Enables `swift package generate-documentation` / hosting DocC catalog.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "BlueBreeze",
            path: "BlueBreeze"
        ),
        .testTarget(
            name: "BlueBreezeTests",
            dependencies: ["BlueBreeze"],
            path: "BlueBreezeTests"
        ),
    ]
)
