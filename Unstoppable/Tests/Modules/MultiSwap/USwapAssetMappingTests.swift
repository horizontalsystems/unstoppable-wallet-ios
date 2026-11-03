import Foundation
import GRDB
import MarketKit
import ObjectMapper
import Testing
@testable import WalletCore

/// The one catalog: `GET /v3/tokens/all` rows mapped to token queries, and the identifier a request names
/// a token by (catalog identifier, else bare address + `chainId`, else nothing).
struct USwapAssetMappingTests {
    private typealias Api = USwapMultiSwapApi

    // MARK: - CatalogToken mapping from the documented shape

    @Test func catalogTokenParsesDocumentedRow() throws {
        let response = try Mapper<Api.CatalogTokenResponse>().map(JSON: [
            "identifier": "ETH.USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48",
            "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            "chain": "ETH",
            "chainId": "1",
            "coingeckoId": "usd-coin",
            "decimals": 6,
            "logoURI": "https://assets.coingecko.com/coins/images/6319/large/USDC.png",
            "name": "USDC",
            "shortCode": NSNull(),
            "ticker": "USDC",
            "providers": ["NEAR", "THORCHAIN", "EXOLIX"],
        ])

        let token = response.token
        #expect(token.identifier == "ETH.USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48")
        #expect(token.address == "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
        #expect(token.chainId == "1")
        #expect(token.decimals == 6)
        #expect(token.shortCode == nil)
        #expect(token.providerIds == ["NEAR", "THORCHAIN", "EXOLIX"])
    }

    @Test func nativeRowHasNullAddress() throws {
        let response = try Mapper<Api.CatalogTokenResponse>().map(JSON: [
            "identifier": "BTC.BTC",
            "address": NSNull(),
            "chain": "BTC",
            "chainId": "bitcoin",
            "decimals": 8,
            "name": "Bitcoin",
            "ticker": "BTC",
            "providers": ["THORCHAIN"],
        ])

        #expect(response.token.address == nil)
    }

    @Test func absentProvidersReadsAsEmpty() throws {
        let response = try Mapper<Api.CatalogTokenResponse>().map(JSON: [
            "identifier": "SOL.SOL",
            "chain": "SOL",
            "chainId": "solana",
            "name": "Solana",
            "ticker": "SOL",
        ])

        #expect(response.token.providerIds.isEmpty)
    }

    // MARK: - catalog(tokens:) per chain family

    @Test func catalogCarriesProviderIdsIntoEntry() {
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "BTC.BTC", address: nil, chain: "BTC", chainId: "bitcoin", providerIds: ["THORCHAIN", "EXOLIX"]),
        ])

        let key = BlockchainType.bitcoin.nativeTokenQueries[0].id.lowercased()
        #expect(catalog[key] == USwapCatalogEntry(identifier: "BTC.BTC", providerIds: ["THORCHAIN", "EXOLIX"]))
    }

    @Test func erc20RowMapsToEip20Query() {
        let address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "ETH.USDC-0XA0B8", address: address, chain: "ETH", chainId: "1", providerIds: ["NEAR"]),
        ])

        let query = TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: address))
        #expect(catalog[query.id.lowercased()]?.identifier == "ETH.USDC-0XA0B8")
    }

    /// The server calls the XRP Ledger "ripple"; without the row the chain is dropped silently.
    @Test func rippleChainMapsToNativeXrp() {
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "XRP.XRP", address: nil, chain: "Ripple", chainId: "ripple"),
        ])

        #expect(catalog[BlockchainType.xrp.nativeTokenQueries[0].id.lowercased()]?.identifier == "XRP.XRP")
    }

    /// Only native XRP is quotable: an issued currency carries an issuer in `address` (Android parity)
    @Test func xrpIssuedCurrencyIsNotMapped() {
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "XRP.RLUSD", address: "rMxCKbEDwqr76QuheSUMdEGf4B9xJ8m5De", chain: "Ripple", chainId: "ripple"),
        ])

        #expect(catalog.isEmpty)
    }

    @Test func nearContractMapsToNep141() {
        let contract = "usdt.tether-token.near"
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "NEAR.USDT-USDT.TETHER-TOKEN.NEAR", address: contract, chain: "Near", chainId: "near"),
        ])

        let query = TokenQuery(blockchainType: .near, tokenType: .nep141(contractId: contract))
        #expect(catalog[query.id.lowercased()]?.identifier == "NEAR.USDT-USDT.TETHER-TOKEN.NEAR")
    }

    @Test func litecoinRowMapsEveryDerivation() {
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "LTC.LTC", address: nil, chain: "LTC", chainId: "litecoin"),
        ])

        #expect(catalog.count == 3)
        #expect(catalog.values.allSatisfy { $0.identifier == "LTC.LTC" })
    }

    @Test func unknownChainIdIsDropped() {
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "FOO.FOO", address: nil, chain: "FOO", chainId: "foo-mainnet"),
        ])

        #expect(catalog.isEmpty)
    }

    /// Two rows for one query: the one more providers list wins, whatever the order.
    @Test func duplicateQueryKeepsEntryWithMoreProviders() {
        let few = Api.CatalogToken(identifier: "ZEC.ZECSHIELDED", address: nil, chain: "ZEC", chainId: "zcash", providerIds: ["EXOLIX"])
        let many = Api.CatalogToken(identifier: "ZEC.ZEC", address: nil, chain: "ZEC", chainId: "zcash", providerIds: ["EXOLIX", "NEAR", "MAYACHAIN"])
        let key = BlockchainType.zcash.nativeTokenQueries[0].id.lowercased()

        for tokens in [[few, many], [many, few]] {
            #expect(USwapAssetMapping.catalog(tokens: tokens)[key]?.identifier == "ZEC.ZEC")
        }
    }

    // MARK: - Codable round-trip through SwapAssetStorage

    @Test func entriesRoundTripThroughStorage() throws {
        let storage = try Self.assetStorage()
        let entries = [
            "ethereum|native": USwapCatalogEntry(identifier: "ETH.ETH", providerIds: ["NEAR", "THORCHAIN"]),
            "bitcoin|native": USwapCatalogEntry(identifier: "BTC.BTC", providerIds: []),
        ]

        try storage.save(swapAssetMap: entries, provider: USwapAssetCatalog.storageKey)
        try storage.save(lastSyncTimestamp: 42, provider: USwapAssetCatalog.storageKey)

        let restored = try storage.swapAssetMap(provider: USwapAssetCatalog.storageKey, as: USwapCatalogEntry.self)
        #expect(restored == entries)
        #expect(try storage.lastSyncTimetamp(provider: USwapAssetCatalog.storageKey) == 42)
    }

    // MARK: - Catalog hit vs bare-address fallback

    @Test func cataloguedTokenResolvesToItsIdentifier() {
        let address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
        let token = Self.token(.ethereum, type: .eip20(address: address))
        let catalog = USwapAssetMapping.catalog(tokens: [
            .init(identifier: "ETH.USDC-0XA0B8", address: address, chain: "ETH", chainId: "1", providerIds: ["NEAR"]),
        ])

        let entry = catalog[token.tokenQuery.id.lowercased()]
        #expect((entry?.identifier ?? USwapAssetMapping.bareAddress(token: token)) == "ETH.USDC-0XA0B8")
    }

    @Test func uncataloguedErc20FallsBackToBareAddress() {
        let address = "0x1111111111111111111111111111111111111111"
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.ethereum, type: .eip20(address: address))) == address)
    }

    @Test func uncataloguedEvmNativeFallsBackToSentinel() {
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.base)) == "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE")
    }

    @Test func uncataloguedSplMintKeepsCase() {
        let mint = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.solana, type: .spl(address: mint))) == mint)
    }

    @Test func otherFamiliesHaveNoBareForm() {
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.bitcoin)) == nil)
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.solana)) == nil)
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.tron, type: .eip20(address: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"))) == nil)
        #expect(USwapAssetMapping.bareAddress(token: Self.token(.stellar, type: .stellar(code: "USDC", issuer: "GA5Z"))) == nil)
    }

    /// A bare address is only meaningful with the sell chain's `chainId`, which every request carries.
    @Test func rateRequestCarriesSellChainId() {
        let request = Api.RateRequest(
            sellAsset: "0x1111111111111111111111111111111111111111",
            buyAsset: "ETH.ETH",
            sellAmount: 1,
            slippage: 1,
            chainId: USwapAssetMapping.chainId(blockchainType: .ethereum)
        )

        #expect(request.parameters["chainId"] as? String == "1")
        #expect(request.parameters["providers"] == nil)
        #expect(request.parameters["privacy"] == nil)
    }

    @Test func chainIdIsTheInverseOfTheMap() {
        #expect(USwapAssetMapping.chainId(blockchainType: .binanceSmartChain) == "56")
        #expect(USwapAssetMapping.chainId(blockchainType: .zcash) == "zcash")
        #expect(USwapAssetMapping.chainId(blockchainType: .unsupported(uid: "nope")) == nil)
    }

    // MARK: - canonical

    @Test func canonicalDropsSymbolAndUppercases() {
        #expect(USwapAssetMapping.canonical("ETH.USDC-0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48") == "ETH.0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48")
        #expect(USwapAssetMapping.canonical("eth.eth") == "ETH.ETH")
        #expect(USwapAssetMapping.canonical("btc-btc") == "BTC-BTC")
        #expect(USwapAssetMapping.canonical("XLM.yXLM-GA5ZSEJYB37J") == "XLM.yXLM-GA5ZSEJYB37J")
    }

    // MARK: - Fixtures

    private static func token(_ blockchainType: BlockchainType, type: TokenType = .native) -> Token {
        Token(
            coin: Coin(uid: blockchainType.uid, name: blockchainType.uid, code: blockchainType.uid.uppercased()),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: type,
            decimals: 8
        )
    }

    /// The two tables as StorageMigrator leaves them; the migrator itself touches the app keychain, so it is not run here
    private static func assetStorage() throws -> SwapAssetStorage {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("uswap-asset-mapping-tests-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)

        try dbPool.write { db in
            try db.create(table: SwapAsset.databaseTableName) { t in
                t.column(SwapAsset.Columns.provider.name, .text).notNull()
                t.column(SwapAsset.Columns.tokenQueryId.name, .text).notNull()
                t.column(SwapAsset.Columns.data.name, .blob).notNull()
                t.primaryKey([SwapAsset.Columns.provider.name, SwapAsset.Columns.tokenQueryId.name], onConflict: .replace)
            }
            try db.create(table: SwapAssetSyncInfo.databaseTableName) { t in
                t.column(SwapAssetSyncInfo.Columns.provider.name, .text).primaryKey(onConflict: .replace)
                t.column(SwapAssetSyncInfo.Columns.lastSyncTimestamp.name, .double).notNull()
            }
        }

        return SwapAssetStorage(dbPool: dbPool)
    }
}
