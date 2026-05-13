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
        .package(url: "https://github.com/horizontalsystems/BitcoinCashKit.Swift", exact: "3.0.1"),
        .package(url: "https://github.com/horizontalsystems/BitcoinCore.Swift", exact: "3.1.5"),
        .package(url: "https://github.com/horizontalsystems/BitcoinKit.Swift", exact: "3.0.1"),
        .package(url: "https://github.com/horizontalsystems/Checkpoints", exact: "1.0.28"),
        .package(url: "https://github.com/horizontalsystems/DashKit.Swift", exact: "3.1.0"),
        .package(url: "https://github.com/horizontalsystems/ECashKit.Swift.git", exact: "3.0.2"),
        .package(url: "https://github.com/horizontalsystems/Eip20Kit.Swift", exact: "2.0.4"),
        .package(url: "https://github.com/horizontalsystems/EvmKit.Swift", exact: "2.4.4"),
        .package(url: "https://github.com/horizontalsystems/FeeRateKit.Swift", exact: "2.1.1"),
        .package(url: "https://github.com/horizontalsystems/HdWalletKit.Swift", exact: "1.3.1"),
        .package(url: "https://github.com/horizontalsystems/Hodler.Swift", exact: "2.0.3"),
        .package(url: "https://github.com/horizontalsystems/HsCryptoKit.Swift", exact: "1.3.2"),
        .package(url: "https://github.com/horizontalsystems/HsToolKit.Swift.git", exact: "2.0.5"),
        .package(url: "https://github.com/horizontalsystems/LitecoinKit.Swift", exact: "3.0.2"),
        .package(url: "https://github.com/horizontalsystems/MarketKit.Swift", exact: "3.6.11"),
        .package(url: "https://github.com/horizontalsystems/MoneroKit.Swift", exact: "0.2.7"),
        .package(url: "https://github.com/horizontalsystems/NftKit.Swift", exact: "2.0.2"),
        .package(url: "https://github.com/horizontalsystems/OneInchKit.Swift", exact: "3.0.4"),
        .package(url: "https://github.com/horizontalsystems/StellarKit.Swift", exact: "1.2.0"),
        .package(url: "https://github.com/horizontalsystems/TonConnectAPI", exact: "1.0.0"),
        .package(url: "https://github.com/horizontalsystems/TonKit.Swift", exact: "1.2.1"),
        .package(url: "https://github.com/horizontalsystems/TronKit.Swift.git", exact: "1.4.0"),
        .package(url: "https://github.com/horizontalsystems/UniswapKit.Swift", exact: "3.2.0"),
        .package(url: "https://github.com/horizontalsystems/ZcashLightClientKit", revision: "f186d017a2d33d50f0276c10adf8b544484acfe6"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.9.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.3"),
        .package(url: "https://github.com/reown-com/reown-swift", exact: "2.0.0"),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper", exact: "4.2.0"),
    ],
    targets: [
        .target(
            name: "WalletCore",
            dependencies: [
                .product(name: "Eip20Kit", package: "Eip20Kit.Swift"),
                .product(name: "EvmKit", package: "EvmKit.Swift"),
                .product(name: "HsCryptoKit", package: "HsCryptoKit.Swift"),
                .product(name: "HsToolKit", package: "HsToolKit.Swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "MarketKit", package: "MarketKit.Swift"),
                .product(name: "NftKit", package: "NftKit.Swift"),
                .product(name: "OneInchKit", package: "OneInchKit.Swift"),
                .product(name: "ObjectMapper", package: "ObjectMapper"),
                .product(name: "RxSwift", package: "RxSwift"),
            ]
        ),
        .target(
            name: "UserInterface",
            dependencies: []
        ),
    ]
)
