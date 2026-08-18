import BigInt
import Foundation
import MarketKit
import ObjectMapper
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainAutoEnableTests {
    private static let ownAddress = "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008"
    private static let otherAddress = "thor1g98cy3n9mmjrpn0sxmn63lztelera37n8n67c0"

    // MARK: - Secured asset map entries

    @Test func securedAssetMapsToThorChainAssetKey() throws {
        let entries = try BaseThorChainMultiSwapProvider.securedAssetMapEntries(
            securedAssets: [Self.securedAsset("BTC-BTC")]
        )

        let expectedKey = TokenQuery(blockchainType: .thorChain, tokenType: .thorChainAsset(denom: "btc-btc")).id.lowercased()
        #expect(entries == [expectedKey: "BTC-BTC"])
    }

    @Test func securedContractAssetKeepsContractInDenomAndOriginalValue() throws {
        let notation = "ETH-USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48"
        let entries = try BaseThorChainMultiSwapProvider.securedAssetMapEntries(
            securedAssets: [Self.securedAsset(notation)]
        )

        let expectedKey = TokenQuery(
            blockchainType: .thorChain,
            tokenType: .thorChainAsset(denom: "eth-usdc-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        ).id.lowercased()
        #expect(entries == [expectedKey: notation])
    }

    @Test func invalidSecuredNotationIsSkipped() throws {
        let entries = try BaseThorChainMultiSwapProvider.securedAssetMapEntries(
            securedAssets: [Self.securedAsset("BTCBTC"), Self.securedAsset("AVAX-AVAX")]
        )

        let expectedKey = TokenQuery(blockchainType: .thorChain, tokenType: .thorChainAsset(denom: "avax-avax")).id.lowercased()
        #expect(entries == [expectedKey: "AVAX-AVAX"])
    }

    private static func securedAsset(_ notation: String) throws -> BaseThorChainMultiSwapProvider.SecuredAsset {
        try BaseThorChainMultiSwapProvider.SecuredAsset(JSONString: "{\"asset\":\"\(notation)\"}")
    }

    // MARK: - Auto-enable queries

    @Test func nativeDenomIsNeverEnabled() throws {
        let tcy = try ThorChainKit.Denom(rawValue: "tcy")
        let queries = ThorChainKitManager.autoEnableQueries(
            denoms: [.rune, tcy],
            nativeDenom: .rune,
            existingTokenTypeIds: [],
            blockchainType: .thorChain
        )

        #expect(queries.map(\.tokenType) == [.thorChainAsset(denom: "tcy")])
    }

    @Test func alreadyEnabledTokensAreDeduped() throws {
        let tcy = try ThorChainKit.Denom(rawValue: "tcy")
        let secured = try ThorChainKit.Denom(rawValue: "btc-btc")
        let existingId = TokenType.thorChainAsset(denom: "tcy").id

        let queries = ThorChainKitManager.autoEnableQueries(
            denoms: [tcy, secured],
            nativeDenom: .rune,
            existingTokenTypeIds: [existingId],
            blockchainType: .thorChain
        )

        #expect(queries.map(\.tokenType) == [.thorChainAsset(denom: "btc-btc")])
    }

    @Test func emptyDenomsYieldNoQueries() {
        let queries = ThorChainKitManager.autoEnableQueries(
            denoms: [],
            nativeDenom: .rune,
            existingTokenTypeIds: [],
            blockchainType: .thorChain
        )

        #expect(queries.isEmpty)
    }

    // MARK: - Incoming denoms from transactions

    @Test func onlyTransfersToOwnAddressCount() throws {
        let transactions = [
            Self.transaction(incoming: [(Self.ownAddress, "THOR.TCY"), (Self.otherAddress, "BTC-BTC")]),
        ]

        let denoms = ThorChainKitManager.incomingDenoms(transactions: transactions, address: Self.ownAddress, chain: .thor)

        let tcy = try ThorChainKit.Denom(rawValue: "tcy")
        #expect(denoms == [tcy])
    }

    @Test func midgardNotationIsCanonicalizedToBankDenoms() throws {
        let transactions = [
            Self.transaction(incoming: [
                (Self.ownAddress, "THOR.TCY"),
                (Self.ownAddress, "BTC-BTC"),
                (Self.ownAddress, "THOR.RUNE"),
            ]),
        ]

        let denoms = ThorChainKitManager.incomingDenoms(transactions: transactions, address: Self.ownAddress, chain: .thor)

        let tcy = try ThorChainKit.Denom(rawValue: "tcy")
        let secured = try ThorChainKit.Denom(rawValue: "btc-btc")
        #expect(denoms == [tcy, secured, .rune])
    }

    private static func transaction(incoming: [(String, String)]) -> ThorChainKit.Transaction {
        ThorChainKit.Transaction(
            transactionId: ThorChainKit.TransactionID(hash: "F0E1D2C3B4A5968778695A4B3C2D1E0F00112233445566778899AABBCCDDEEFF")!,
            blockHeight: 27_000_000,
            timestamp: Date(timeIntervalSince1970: 1_785_427_946),
            type: "send",
            status: "success",
            memo: nil,
            incoming: incoming.map { ThorChainKit.CoinTransfer(address: $0.0, asset: $0.1, amount: BigUInt(100_000_000)) },
            outgoing: []
        )
    }
}
