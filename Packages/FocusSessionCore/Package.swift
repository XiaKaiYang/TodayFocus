// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FocusSessionCore",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "FocusSessionCore",
            targets: ["FocusSessionCore"]
        ),
    ],
    targets: [
        .target(
            name: "FocusSessionCore"
        ),
        .testTarget(
            name: "FocusSessionCoreTests",
            dependencies: ["FocusSessionCore"]
        ),
    ]
)
