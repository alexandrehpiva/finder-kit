// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "finder-kit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FinderKitCore", targets: ["FinderKitCore"]),
        .executable(name: "finder-kit", targets: ["finder-kit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "FinderKitCore",
            path: "Sources/FinderKitCore"
        ),
        .executableTarget(
            name: "finder-kit",
            dependencies: [
                "FinderKitCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/finder-kit",
            linkerSettings: [
                .linkedFramework("AppKit"),
            ]
        ),
        .testTarget(
            name: "FinderKitCoreTests",
            dependencies: [
                "FinderKitCore",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/FinderKitCoreTests"
        ),
    ]
)
