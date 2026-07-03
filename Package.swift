// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SkillHub",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
        .package(url: "https://github.com/raspu/Highlightr", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "SkillHub",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Highlightr", package: "Highlightr")
            ],
            path: "Sources/SkillHub"
        ),
        .testTarget(
            name: "SkillHubTests",
            dependencies: ["SkillHub"],
            path: "Tests/SkillHubTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
