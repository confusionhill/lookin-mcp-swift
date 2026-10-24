// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "lookin-mcp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "lookin-mcp", targets: ["LookinMCP"]),
        .library(name: "LookinClient", targets: ["LookinClient"]),
        .library(name: "LookinModels", targets: ["LookinModels"])
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", "1.0.0"..<"1.16.2"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", "2.0.0"..<"2.13.0")
    ],
    targets: [
        .executableTarget(
            name: "LookinMCP",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "Logging", package: "swift-log"),
                "LookinClient",
                "LookinModels"
            ],
            path: "Sources/LookinMCP"
        ),
        .target(
            name: "LookinClient",
            dependencies: ["LookinModels"],
            path: "Sources/LookinClient"
        ),
        .target(
            name: "LookinModels",
            path: "Sources/LookinModels"
        ),
        .testTarget(
            name: "LookinClientTests",
            dependencies: ["LookinClient", "LookinModels"],
            path: "Tests/LookinClientTests"
        )
    ]
)
