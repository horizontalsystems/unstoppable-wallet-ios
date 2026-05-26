// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "WalletCore", targets: ["WalletCore"]),
        .library(name: "UserInterface", targets: ["UserInterface"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", exact: "5.3.0"),
        .package(url: "https://github.com/horizontalsystems/Eip20Kit.Swift", exact: "2.0.4"),
        .package(url: "https://github.com/horizontalsystems/EvmKit.Swift", exact: "2.4.4"),
        .package(url: "https://github.com/groue/GRDB.swift.git", exact: "6.29.3"),
        .package(url: "https://github.com/horizontalsystems/HdWalletKit.Swift", exact: "1.3.1"),
        .package(url: "https://github.com/horizontalsystems/HsCryptoKit.Swift", exact: "1.3.2"),
        .package(url: "https://github.com/horizontalsystems/HsExtensions.Swift.git", exact: "1.0.6"),
        .package(url: "https://github.com/horizontalsystems/HsToolKit.Swift.git", exact: "2.0.5"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        .package(url: "https://github.com/horizontalsystems/MarketKit.Swift", exact: "3.6.11"),
        .package(url: "https://github.com/horizontalsystems/OneInchKit.Swift", exact: "3.0.4"),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper", exact: "4.2.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.3"),
        .package(url: "https://github.com/horizontalsystems/TronKit.Swift.git", exact: "1.5.1"),
    ],
    targets: [
        .target(
            name: "WalletCore",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Eip20Kit", package: "Eip20Kit.Swift"),
                .product(name: "EvmKit", package: "EvmKit.Swift"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "HdWalletKit", package: "HdWalletKit.Swift"),
                .product(name: "HsCryptoKit", package: "HsCryptoKit.Swift"),
                .product(name: "HsExtensions", package: "HsExtensions.Swift"),
                .product(name: "HsToolKit", package: "HsToolKit.Swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "MarketKit", package: "MarketKit.Swift"),
                .product(name: "OneInchKit", package: "OneInchKit.Swift"),
                .product(name: "ObjectMapper", package: "ObjectMapper"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "TronKit", package: "TronKit.Swift"),
            ],
            resources: [
                .process("Resources/Localizable.xcstrings"),
            ]
        ),
        .target(
            name: "UserInterface",
            dependencies: []
        ),
    ]
)
