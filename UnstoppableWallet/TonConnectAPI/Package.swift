// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TonConnectAPI",
    platforms: [
        .macOS(.v12), .iOS(.v13)
    ],
    products: [
        .library(name: "TonConnectAPI", targets: ["TonConnectAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.3.0")),
    ],
    targets: [
        .target(name: "TonConnectAPI",
                dependencies: [
                    .product(
                        name: "OpenAPIRuntime",
                        package: "swift-openapi-runtime"
                    )
                ],
                path: "Sources",
                sources: ["TonConnectAPI"]
               )
    ]
)
