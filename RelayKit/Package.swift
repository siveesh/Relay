// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RelayKit",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .library(name: "RelayCore", targets: ["RelayCore"]),
        .library(name: "RelayStorage", targets: ["RelayStorage"]),
        .library(name: "RelaySearch", targets: ["RelaySearch"]),
        .library(name: "RelayTasks", targets: ["RelayTasks"]),
        .library(name: "RelaySecurity", targets: ["RelaySecurity"]),
        .library(name: "RelayNotifications", targets: ["RelayNotifications"]),
        .library(name: "RelayCommandPacks", targets: ["RelayCommandPacks"]),
        .library(name: "RelayUI", targets: ["RelayUI"]),
    ],
    targets: [
        // Root domain module — depends on nothing else in RelayKit.
        .target(name: "RelayCore"),

        .target(name: "RelayStorage", dependencies: ["RelayCore"]),
        .target(name: "RelaySearch", dependencies: ["RelayCore"]),
        .target(name: "RelayTasks", dependencies: ["RelayCore"]),
        .target(name: "RelaySecurity", dependencies: ["RelayCore"]),
        .target(name: "RelayNotifications", dependencies: ["RelayCore"]),
        .target(name: "RelayCommandPacks", dependencies: ["RelayCore", "RelayStorage"]),
        .target(name: "RelayUI", dependencies: ["RelayCore"]),

        // Tests for the modules carrying real M1 logic.
        .testTarget(name: "RelayCoreTests", dependencies: ["RelayCore"]),
        .testTarget(name: "RelayStorageTests", dependencies: ["RelayStorage"]),
        .testTarget(name: "RelaySearchTests", dependencies: ["RelaySearch"]),
    ]
)
