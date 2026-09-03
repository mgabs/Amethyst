// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Silica",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "Silica", targets: ["Silica"])
    ],
    targets: [
        .target(
            name: "Silica",
            path: "Sources/Silica",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "SilicaTests",
            dependencies: ["Silica"],
            path: "Tests/SilicaTests"
        )
    ]
)
