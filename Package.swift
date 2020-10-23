// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftyPlayer",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "SwiftyPlayer",
            targets: ["SwiftyPlayer"]
        ),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "SwiftyPlayer",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftyPlayerTests",
            dependencies: ["SwiftyPlayer"],
            path: "Tests"
        ),
    ]
)
