// swift-tools-version: 5.10
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
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "LookinMCP",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
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
