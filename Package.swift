// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RunestoneUI",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RunestoneUI",
            targets: ["RunestoneUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/xibbon/Runestone", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RunestoneUI",
            dependencies: [
                .product (name: "Runestone", package: "Runestone")
            ]),
        .testTarget(
            name: "RunestoneUITests",
            dependencies: ["RunestoneUI"]),
    ]
)
