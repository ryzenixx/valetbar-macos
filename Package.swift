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
    targets: [
        .executableTarget(
            name: "ValetBar",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
