// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ValetBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ValetBar", targets: ["ValetBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "ValetBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources",
            resources: [
                .copy("Assets")
            ]
        ),
    ]
)
