// swift-tools-version: 6.0
import PackageDescription

// Domain layer: models, the template step engine, and the session state machine.
// Deliberately free of SwiftUI so its tests run without launching a simulator.
// macOS is listed only so `swift test` works from the command line; the app ships iOS-only.
let package = Package(
    name: "KindlingCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KindlingCore", targets: ["KindlingCore"])
    ],
    targets: [
        .target(
            name: "KindlingCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "KindlingCoreTests",
            dependencies: ["KindlingCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
