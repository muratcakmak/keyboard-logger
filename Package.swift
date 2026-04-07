// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KeyboardLogger",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "KeyboardLoggerApp", targets: ["KeyboardLoggerApp"]),
        .executable(name: "keyboard-logger", targets: ["KeyboardLoggerCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "KeyboardLoggerShared",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .executableTarget(
            name: "KeyboardLoggerApp",
            dependencies: ["KeyboardLoggerShared"]
        ),
        .executableTarget(
            name: "KeyboardLoggerCLI",
            dependencies: [
                "KeyboardLoggerShared",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "KeyboardLoggerSharedTests",
            dependencies: ["KeyboardLoggerShared"]
        ),
    ]
)
