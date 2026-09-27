// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PromptKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PromptKit", targets: ["PromptKit"])
    ],
    targets: [
        .target(
            name: "PromptKit", path: "Sources",
            resources: [.process("PromptKit/Localizable.xcstrings")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "PromptKitTests", dependencies: ["PromptKit"], path: "Tests"),
    ]
)
