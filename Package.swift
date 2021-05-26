// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantle",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "Mantle",
            targets: ["Mantle"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.5"),
//        .package(url: "https://github.com/Quick/Quick.git", from: "2.2.0"),
    ],
    targets: [
        .target(
            name: "Mantle",
            dependencies: ["extobjc"],
            path: "Mantle",
            exclude: [
                "extobjc",
            ],
            publicHeadersPath: "include",
            cSettings: [
                    .define("MANTLE_SPM", to: "1"),  // Prevent framework import headers
            ]),
        .target(
            name: "extobjc",
            dependencies: [],
            path: "Mantle/extobjc",
            publicHeadersPath: ".")
// Note: this is commented out as SPM doesn't currently support ObjC/Swift mixed targets
//        .testTarget(
//            name: "MantleTests",
//            dependencies: ["Mantle", "Nimble", "Quick"],
//            path: "MantleTests"),
    ]
)
