//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BlueBreeze",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "BlueBreeze", targets: ["BlueBreeze"]),
    ],
    targets: [
        .target(
            name: "BlueBreeze",
            path: "BlueBreeze"
        ),
    ]
)
