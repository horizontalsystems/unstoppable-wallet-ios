import Foundation
import MarketKit
import Testing
@testable import WalletCore

/// Freezes the static facts of every supported blockchain as read through the public-facing members,
/// so moving a chain's rows into its plugin's descriptor cannot change a value. The literals were taken
/// from the code before any chain moved. `uriPath(address:)` is left out: it reads the EVM manager.
/// `defaultTokenQuery` of bitcoin, litecoin and bitcoinCash follows the constants
/// `MnemonicDerivation.default` (bip84) and `BitcoinCashCoinType.default` (type145).
struct BlockchainDescriptorParityTests {
    @Test(arguments: rows)
    func chainFacts(row: BlockchainDescriptorParityRow) throws {
        try #require(Core.instance != nil)

        let type = row.type
        let uid = type.uid

        #expect(type.order == row.order, "\(uid) order")
        #expect(type.memoType == row.memoType, "\(uid) memoType")
        #expect(type.memoMaxBytes == row.memoMaxBytes, "\(uid) memoMaxBytes")
        #expect(type.memoRidesOpReturn == row.memoRidesOpReturn, "\(uid) memoRidesOpReturn")
        #expect(type.uriScheme == row.uriScheme, "\(uid) uriScheme")
        #expect(type.feePriceScale == row.feePriceScale, "\(uid) feePriceScale")
        #expect(type.resendable == row.resendable, "\(uid) resendable")
        #expect(type.restoreSettingTypes.map(\.rawValue) == row.restoreSettingTypes, "\(uid) restoreSettingTypes")
        #expect(type.defaultTokenQuery.id == row.defaultTokenQuery, "\(uid) defaultTokenQuery")
        #expect(type.nativeTokenQueries.map(\.id) == row.nativeTokenQueries, "\(uid) nativeTokenQueries")
        #expect(type.supports(restoreMode: .blockchair) == row.supportsBlockchair, "\(uid) supports(restoreMode: .blockchair)")
        #expect(type.blockTime == row.blockTime, "\(uid) blockTime")
        #expect(type.description == row.description, "\(uid) description")
        #expect(token(type, .native).sendToSelfAllowed == row.sendToSelfAllowed, "\(uid) sendToSelfAllowed")
    }

    @Test func supportedTypes() throws {
        try #require(Core.instance != nil)

        #expect(BlockchainType.supported.map(\.uid) == [
            "bitcoin", "bitcoin-cash", "ecash", "litecoin", "dash", "zcash", "monero", "zano", "ethereum", "polygon-pos", "avalanche",
            "optimistic-ethereum", "arbitrum-one", "gnosis", "fantom", "base", "zksync", "robinhood", "arc", "binance-smart-chain", "tron",
            "thorchain", "mayachain", "the-open-network", "stellar", "xrp", "near-protocol", "solana",
        ])
        #expect(rows.map(\.type) == BlockchainType.supported)
    }

    @Test func sendToSelfAllowedForTokens() throws {
        try #require(Core.instance != nil)

        #expect(token(.zcash, .eip20(address: "0xtoken")).sendToSelfAllowed)
        #expect(!token(.tron, .eip20(address: "0xtoken")).sendToSelfAllowed)
        #expect(!token(.near, .nep141(contractId: "usdt.tether-token.near")).sendToSelfAllowed)
    }
}

struct BlockchainDescriptorParityRow: CustomTestStringConvertible {
    let type: BlockchainType
    let order: Int
    let memoType: MemoType
    let memoMaxBytes: Int?
    let memoRidesOpReturn: Bool
    let uriScheme: String?
    let feePriceScale: FeePriceScale
    let resendable: Bool
    let restoreSettingTypes: [String]
    let defaultTokenQuery: String
    let nativeTokenQueries: [String]
    let supportsBlockchair: Bool
    let blockTime: TimeInterval?
    let description: String
    let sendToSelfAllowed: Bool

    var testDescription: String {
        type.uid
    }
}

private let rows: [BlockchainDescriptorParityRow] = [
    .init(type: .bitcoin, order: 0, memoType: .onChainPublic, memoMaxBytes: 80, memoRidesOpReturn: true, uriScheme: "bitcoin", feePriceScale: .satoshi, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "bitcoin|derived:bip84", nativeTokenQueries: ["bitcoin|derived:bip44", "bitcoin|derived:bip49", "bitcoin|derived:bip84", "bitcoin|derived:bip86"], supportsBlockchair: true, blockTime: 600, description: "BTC (BIP44, BIP49, BIP84, BIP86)", sendToSelfAllowed: true),
    .init(type: .bitcoinCash, order: 19, memoType: .onChainPublic, memoMaxBytes: 220, memoRidesOpReturn: true, uriScheme: "bitcoincash", feePriceScale: .satoshi, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "bitcoin-cash|address_type:type145", nativeTokenQueries: ["bitcoin-cash|address_type:type0", "bitcoin-cash|address_type:type145"], supportsBlockchair: true, blockTime: 600, description: "BCH (Legacy, CashAddress)", sendToSelfAllowed: true),
    .init(type: .ecash, order: 22, memoType: .onChainPublic, memoMaxBytes: 220, memoRidesOpReturn: true, uriScheme: "ecash", feePriceScale: .satoshi, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "ecash|native", nativeTokenQueries: ["ecash|native"], supportsBlockchair: false, blockTime: 600, description: "XEC", sendToSelfAllowed: true),
    .init(type: .litecoin, order: 18, memoType: .onChainPublic, memoMaxBytes: 80, memoRidesOpReturn: true, uriScheme: "litecoin", feePriceScale: .satoshi, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "litecoin|derived:bip84", nativeTokenQueries: ["litecoin|derived:bip44", "litecoin|derived:bip49", "litecoin|derived:bip84", "litecoin|derived:bip86"], supportsBlockchair: true, blockTime: 150, description: "LTC (BIP44, BIP49, BIP84, BIP86)", sendToSelfAllowed: true),
    .init(type: .dash, order: 17, memoType: .onChainPublic, memoMaxBytes: 80, memoRidesOpReturn: true, uriScheme: "dash", feePriceScale: .satoshi, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "dash|native", nativeTokenQueries: ["dash|native"], supportsBlockchair: false, blockTime: 150, description: "DASH", sendToSelfAllowed: true),
    .init(type: .zcash, order: 3, memoType: .onChainPrivate, memoMaxBytes: 512, memoRidesOpReturn: false, uriScheme: "zcash", feePriceScale: .gwei, resendable: true, restoreSettingTypes: ["birthday_height"], defaultTokenQuery: "zcash|native", nativeTokenQueries: ["zcash|native"], supportsBlockchair: false, blockTime: 75, description: "ZEC", sendToSelfAllowed: false),
    .init(type: .monero, order: 2, memoType: .local, memoMaxBytes: 120, memoRidesOpReturn: false, uriScheme: "monero", feePriceScale: .gwei, resendable: true, restoreSettingTypes: ["birthday_height"], defaultTokenQuery: "monero|native", nativeTokenQueries: ["monero|native"], supportsBlockchair: false, blockTime: 120, description: "XMR", sendToSelfAllowed: true),
    .init(type: .zano, order: 4, memoType: .onChainPrivate, memoMaxBytes: 120, memoRidesOpReturn: false, uriScheme: "zano", feePriceScale: .gwei, resendable: true, restoreSettingTypes: ["birthday_height"], defaultTokenQuery: "zano|native", nativeTokenQueries: ["zano|native"], supportsBlockchair: false, blockTime: 60, description: "ZANO, confidential assets", sendToSelfAllowed: true),
    .init(type: .ethereum, order: 1, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "ethereum|native", nativeTokenQueries: ["ethereum|native"], supportsBlockchair: false, blockTime: 12, description: "ETH, ERC20 tokens", sendToSelfAllowed: true),
    .init(type: .polygon, order: 11, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "polygon-pos|native", nativeTokenQueries: ["polygon-pos|native"], supportsBlockchair: false, blockTime: 2, description: "MATIC, ERC20 tokens", sendToSelfAllowed: true),
    .init(type: .avalanche, order: 20, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .nAvax, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "avalanche|native", nativeTokenQueries: ["avalanche|native"], supportsBlockchair: false, blockTime: 2, description: "AVAX, ERC20 tokens", sendToSelfAllowed: true),
    .init(type: .optimism, order: 13, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: false, restoreSettingTypes: [], defaultTokenQuery: "optimistic-ethereum|native", nativeTokenQueries: ["optimistic-ethereum|native"], supportsBlockchair: false, blockTime: 2, description: "L2 chain", sendToSelfAllowed: true),
    .init(type: .arbitrumOne, order: 12, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: false, restoreSettingTypes: [], defaultTokenQuery: "arbitrum-one|native", nativeTokenQueries: ["arbitrum-one|native"], supportsBlockchair: false, blockTime: 1, description: "L2 chain", sendToSelfAllowed: true),
    .init(type: .gnosis, order: 26, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "gnosis|native", nativeTokenQueries: ["gnosis|native"], supportsBlockchair: false, blockTime: 5, description: "xDAI, ERC20 tokens", sendToSelfAllowed: true),
    .init(type: .fantom, order: 27, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "fantom|native", nativeTokenQueries: ["fantom|native"], supportsBlockchair: false, blockTime: 2, description: "FTM, ERC20 tokens", sendToSelfAllowed: true),
    .init(type: .base, order: 10, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: false, restoreSettingTypes: [], defaultTokenQuery: "base|native", nativeTokenQueries: ["base|native"], supportsBlockchair: false, blockTime: 2, description: "L2 chain", sendToSelfAllowed: true),
    .init(type: .zkSync, order: 23, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: false, restoreSettingTypes: [], defaultTokenQuery: "zksync|native", nativeTokenQueries: ["zksync|native"], supportsBlockchair: false, blockTime: 2, description: "L2 chain", sendToSelfAllowed: true),
    .init(type: .robinhood, order: 24, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: false, restoreSettingTypes: [], defaultTokenQuery: "robinhood|native", nativeTokenQueries: ["robinhood|native"], supportsBlockchair: false, blockTime: 2, description: "L2 chain", sendToSelfAllowed: true),
    .init(type: .arc, order: 25, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: false, restoreSettingTypes: [], defaultTokenQuery: "arc|native", nativeTokenQueries: ["arc|native"], supportsBlockchair: false, blockTime: 1, description: "USDC, ERC20 tokens", sendToSelfAllowed: true),
    .init(type: .binanceSmartChain, order: 5, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "ethereum", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "binance-smart-chain|native", nativeTokenQueries: ["binance-smart-chain|native"], supportsBlockchair: false, blockTime: 1, description: "BNB, BEP20 tokens", sendToSelfAllowed: true),
    .init(type: .tron, order: 7, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "tron", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "tron|native", nativeTokenQueries: ["tron|native"], supportsBlockchair: false, blockTime: 3, description: "TRX, TRC20 tokens", sendToSelfAllowed: false),
    .init(type: .thorChain, order: 8, memoType: .onChainPublic, memoMaxBytes: 250, memoRidesOpReturn: false, uriScheme: nil, feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "thorchain|native", nativeTokenQueries: ["thorchain|native"], supportsBlockchair: false, blockTime: nil, description: "RUNE, THORChain assets", sendToSelfAllowed: true),
    .init(type: .mayaChain, order: 9, memoType: .onChainPublic, memoMaxBytes: 250, memoRidesOpReturn: false, uriScheme: nil, feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "mayachain|native", nativeTokenQueries: ["mayachain|native"], supportsBlockchair: false, blockTime: nil, description: "CACAO", sendToSelfAllowed: true),
    .init(type: .ton, order: 21, memoType: .onChainPublic, memoMaxBytes: 120, memoRidesOpReturn: false, uriScheme: "ton", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "the-open-network|native", nativeTokenQueries: ["the-open-network|native"], supportsBlockchair: false, blockTime: 5, description: "TON", sendToSelfAllowed: true),
    .init(type: .stellar, order: 14, memoType: .onChainPublic, memoMaxBytes: 28, memoRidesOpReturn: false, uriScheme: "stellar", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "stellar|native", nativeTokenQueries: ["stellar|native"], supportsBlockchair: false, blockTime: 5, description: "Stellar", sendToSelfAllowed: true),
    .init(type: .xrp, order: 15, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "xrp", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "xrp|native", nativeTokenQueries: ["xrp|native"], supportsBlockchair: false, blockTime: 4, description: "XRP, XRPL tokens", sendToSelfAllowed: false),
    .init(type: .near, order: 16, memoType: .none, memoMaxBytes: 256, memoRidesOpReturn: false, uriScheme: nil, feePriceScale: .gwei, resendable: true, restoreSettingTypes: ["near_account_id"], defaultTokenQuery: "near-protocol|native", nativeTokenQueries: ["near-protocol|native"], supportsBlockchair: false, blockTime: 1, description: "NEAR, NEP-141 tokens", sendToSelfAllowed: false),
    .init(type: .solana, order: 6, memoType: .none, memoMaxBytes: nil, memoRidesOpReturn: false, uriScheme: "solana", feePriceScale: .gwei, resendable: true, restoreSettingTypes: [], defaultTokenQuery: "solana|native", nativeTokenQueries: ["solana|native"], supportsBlockchair: false, blockTime: nil, description: "SOL, SPL tokens", sendToSelfAllowed: true),
]

private func token(_ blockchainType: BlockchainType, _ tokenType: TokenType) -> Token {
    Token(
        coin: Coin(uid: "coin", name: "Coin", code: "COIN"),
        blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
        type: tokenType,
        decimals: 18
    )
}
