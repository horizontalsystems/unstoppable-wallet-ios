import MarketKit
import Testing
@testable import WalletCore

struct USwapAssetMappingTests {
    @Test func exolixNativeZcashAssetIsIndependentOfTokenOrder() {
        let transparent = token(identifier: "ZEC.ZEC")
        let shielded = token(identifier: "ZEC.ZECSHIELDED")

        for tokens in [[transparent, shielded], [shielded, transparent]] {
            let assetMap = USwapAssetRepository.assetMap(
                tokens: tokens,
                includeAsset: ExolixUSwapSubProvider.includesInAssetMap(identifier:)
            )

            #expect(assetMap[zcashTokenQueryId] == "ZEC.ZEC")
        }
    }

    @Test func exolixShieldedOnlyResponseDoesNotEnableNativeZcash() {
        let assetMap = USwapAssetRepository.assetMap(
            tokens: [token(identifier: "ZEC.ZECSHIELDED")],
            includeAsset: ExolixUSwapSubProvider.includesInAssetMap(identifier:)
        )

        #expect(assetMap[zcashTokenQueryId] == nil)
    }

    @Test func exolixTransparentOnlyResponseEnablesNativeZcash() {
        let assetMap = USwapAssetRepository.assetMap(
            tokens: [token(identifier: "ZEC.ZEC")],
            includeAsset: ExolixUSwapSubProvider.includesInAssetMap(identifier:)
        )

        #expect(assetMap[zcashTokenQueryId] == "ZEC.ZEC")
    }

    @Test func exolixAssetFilterKeepsUnrelatedAssets() {
        let assetMap = USwapAssetRepository.assetMap(
            tokens: [
                .init(
                    chain: "Bitcoin",
                    chainId: "bitcoin",
                    address: nil,
                    identifier: "BTC.BTC"
                ),
            ],
            includeAsset: ExolixUSwapSubProvider.includesInAssetMap(identifier:)
        )

        let bitcoinTokenQueryId = BlockchainType.bitcoin.nativeTokenQueries[0].id.lowercased()
        #expect(assetMap[bitcoinTokenQueryId] == "BTC.BTC")
    }

    private var zcashTokenQueryId: String {
        BlockchainType.zcash.nativeTokenQueries[0].id.lowercased()
    }

    private func token(identifier: String) -> USwapMultiSwapApi.Token {
        .init(
            chain: "Zcash",
            chainId: "zcash",
            address: nil,
            identifier: identifier
        )
    }
}
