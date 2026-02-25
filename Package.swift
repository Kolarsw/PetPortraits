// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PetPortraits",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PetPortraits",
            targets: ["PetPortraits"]),
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "PetPortraits",
            dependencies: []),
        .testTarget(
            name: "PetPortraitsTests",
            dependencies: [
                "PetPortraits",
                "SwiftCheck"
            ]),
    ]
)
