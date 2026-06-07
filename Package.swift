// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ModelWatch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ModelWatch", targets: ["ModelWatch"])
    ],
    targets: [
        .executableTarget(
            name: "ModelWatch"
        ),
        .testTarget(
            name: "ModelWatchTests",
            dependencies: ["ModelWatch"]
        )
    ]
)
