// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PromptKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "PromptKit", targets: ["PromptKit"]),
    ],
    targets: [
        .target(name: "PromptKit", path: "Sources",
                swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]),
        .testTarget(name: "PromptKitTests", dependencies: ["PromptKit"], path: "Tests"),
    ]
)
