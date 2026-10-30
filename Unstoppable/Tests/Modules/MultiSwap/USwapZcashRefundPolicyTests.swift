import Foundation
import MarketKit
import Testing
@testable import WalletCore

/// Which providers take a unified ZEC refund (USwapProviderInfo.acceptsUnifiedZcashRefund), and that a ZEC sell names
/// no source address to any other provider or when the host app turns the source hook off (spec 2026-10-19). The
/// negative branches of USwapCommitRequestBuilder return before touching Core.shared, so no fixtures beyond the token.
struct USwapZcashRefundPolicyTests {
    @Test(arguments: ["MAYACHAIN", "NEAR"])
    func unifiedRefundProviders(id: String) throws {
        let info = try #require(SwapProviderResolver.providerInfo(id: id))
        #expect(info.acceptsUnifiedZcashRefund)
    }

    @Test(arguments: [
        "NEAR_CONFIDENTIAL", "QUICKEX", "LETSEXCHANGE", "STEALTHEX", "SWAPUZ", "EXOLIX", "CCE", "BARTER", "SOROSWAP",
        "AQUARIUS", "STELLAR_DEX", "STELLARBROKER", "PEGASUS", "CIRCLE", "JUPITER", "LIFI", "ONEINCH", "UNISWAP",
        "THORCHAIN", "AXELAR_ITS", "LIZEX", "BITANIA", "XSWAP",
    ])
    func transparentRefundProviders(id: String) throws {
        let info = try #require(SwapProviderResolver.providerInfo(id: id))
        #expect(!info.acceptsUnifiedZcashRefund)
    }

    @Test(arguments: ["QUICKEX", "STEALTHEX", "EXOLIX", "THORCHAIN", "SWAPUZ", "LIZEX", "XSWAP", "NEAR_CONFIDENTIAL"])
    func zcashSellNamesNoSourceWithoutUnifiedRefund(id: String) async throws {
        let source = try await USwapCommitRequestBuilder(providerId: id).sourceAddress(token: Self.zec)
        #expect(source == nil)
    }

    @Test(arguments: ["MAYACHAIN", "NEAR"])
    func sourceHookOffNamesNoSource(id: String) async throws {
        let builder = USwapCommitRequestBuilder(providerId: id, shouldIncludeSourceAddress: { _ in false })
        let source = try await builder.sourceAddress(token: Self.zec)
        #expect(source == nil)
    }

    private static let zec = Token(
        coin: Coin(uid: "zcash", name: "Zcash", code: "ZEC"),
        blockchain: Blockchain(type: .zcash, name: "Zcash", explorerUrl: nil),
        type: .native,
        decimals: 8
    )
}
