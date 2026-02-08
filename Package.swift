// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "morugauge",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "morugauge",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        )
    ]
)

