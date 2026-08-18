// swift-tools-version: 6.0
import PackageDescription

// Design system and the Ember. A separate package from the app target because the
// widget extension must import the tokens and the Ember too.
let package = Package(
    name: "KindlingUI",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KindlingUI", targets: ["KindlingUI"])
    ],
    targets: [
        .target(
            name: "KindlingUI",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
