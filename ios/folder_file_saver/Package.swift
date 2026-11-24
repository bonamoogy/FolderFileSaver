// swift-tools-version: 5.9
// Swift Package Manager manifest, used by apps that have Swift Package Manager enabled.

import PackageDescription

let package = Package(
    name: "folder_file_saver",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "folder-file-saver", targets: ["folder_file_saver"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "folder_file_saver",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("Photos")
            ]
        )
    ]
)
