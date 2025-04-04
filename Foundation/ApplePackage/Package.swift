// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApplePackage",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "ApplePackage",
            targets: ["ApplePackage"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
    ],
    targets: [
        .target(
            name: "ApplePackage", dependencies: [
                "AnyCodable",
                "ZIPFoundation",
            ]
        ),
        .testTarget(
            name: "ApplePackageTests",
            dependencies: ["ApplePackage"]
        ),
    ]
)
