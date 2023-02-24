// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "Toast",
    platforms: [
        .iOS(.v8),
    ],
    products: [
        .library(name: "Toast-static", type: .static, targets: ["Toast"]),
        .library(name: "Toast-dynamic", type: .dynamic, targets: ["Toast"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Toast", dependencies: [], path: "Toast"),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
