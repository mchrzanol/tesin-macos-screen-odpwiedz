// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TestAnswerBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TestAnswerBar",
            path: "TestAnswerBar",
            exclude: ["Info.plist", "TestAnswerBar.entitlements"]
        )
    ]
)
