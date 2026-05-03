//
//  Package.swift
//  VectorImage
//
//  Declares the VectorImage package and its targets.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

// swift-tools-version: 6.0
import PackageDescription

extension Array where Element == SwiftSetting {
    static let vectorImageDefaults: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .swiftLanguageMode(.v6)
    ]
}

let package = Package(
    name: "VectorImage",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "VectorImageCore",
            targets: ["VectorImageCore"]
        ),
        .library(
            name: "VectorImageAdvanced",
            targets: ["VectorImageAdvanced"]
        ),
        .library(
            name: "VectorImageUI",
            targets: ["VectorImageUI"]
        )
    ],
    targets: [
        .target(
            name: "VectorImageCore",
            swiftSettings: .vectorImageDefaults
        ),
        .target(
            name: "VectorImageAdvanced",
            dependencies: ["VectorImageCore"],
            swiftSettings: .vectorImageDefaults
        ),
        .target(
            name: "VectorImageUI",
            dependencies: ["VectorImageCore"],
            swiftSettings: .vectorImageDefaults
        ),
        .testTarget(
            name: "VectorImageCoreTests",
            dependencies: ["VectorImageCore"],
            resources: [
                .process("Fixtures")
            ],
            swiftSettings: .vectorImageDefaults
        ),
        .testTarget(
            name: "VectorImageUITests",
            dependencies: ["VectorImageUI"],
            swiftSettings: .vectorImageDefaults
        )
    ]
)
