// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.55.0"),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
