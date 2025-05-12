// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vidio",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "vidio",
            targets: ["vidio"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tanersener/mobile-ffmpeg-full.git", from: "4.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "vidio",
            dependencies: [
                .product(name: "mobile-ffmpeg-full", package: "mobile-ffmpeg-full")
            ]),
    ]
)
