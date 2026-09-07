// swift-tools-version:5.1

import PackageDescription

var products: [Product] = [
    .library(
        name: "MantleCodable",
        targets: ["MantleCodable"]
    )
]

var targets: [Target] = [
    .target(
        name: "MantleCodable",
        path: "MantleCodable"
    ),
    .testTarget(
        name: "MantleCodableTests",
        dependencies: ["MantleCodable"],
        path: "MantleCodableTests"
    )
]

// The original Mantle/extobjc targets are Objective-C and rely on the Apple Objective-C runtime
// and Foundation headers, neither of which exist on Linux or Windows, so they're only buildable
// on Apple platforms. `swift build`/`swift test` on Linux/Windows only see MantleCodable above.
#if canImport(ObjectiveC)
products.append(
    .library(
        name: "Mantle",
        targets: ["Mantle"]
    )
)

targets.append(contentsOf: [
    .target(
        name: "Mantle",
        dependencies: ["extobjc"],
        path: "Mantle",
        exclude: ["extobjc"]
    ),
    .target(
        name: "extobjc",
        path: "Mantle/extobjc"
    )
])
#endif

let package = Package(
    name: "Mantle",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: products,
    targets: targets
)
