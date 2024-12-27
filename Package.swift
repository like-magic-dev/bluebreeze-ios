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
