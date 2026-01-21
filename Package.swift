// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DisableSleepMenu",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DisableSleepMenu",
            path: "Sources/DisableSleepMenu",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
