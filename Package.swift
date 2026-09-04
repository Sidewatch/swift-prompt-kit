// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PromptKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PromptKit", targets: ["PromptKit"]),
    ],
    targets: [
        .target(name: "PromptKit", path: "Sources",
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "PromptKitTests", dependencies: ["PromptKit"], path: "Tests"),
    ]
)
