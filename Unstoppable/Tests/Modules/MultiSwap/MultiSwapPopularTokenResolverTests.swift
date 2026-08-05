import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

// context-aware Popular Tokens formula, ported from Android SwapPopularTokens:
// Case A (non-native context) -> own-chain native first, Case B (native) -> same-chain USDT first
struct MultiSwapPopularTokenResolverTests {
    @Test func noContextStartsWithBitcoinAndFollowsFormula() {
        let result = MultiSwapPopularTokenResolver.tokens(marketKit: Self.stub(), for: nil)

        #expect(ids(result) == ids([Self.btc, Self.eth, Self.xmr, Self.zec, Self.trx, Self.usdtEth, Self.usdcEth, Self.usdtTron, Self.usdtBsc, Self.usdtBase]))
    }

    @Test func nativeContextPutsSameChainStablesFirst() {
        let result = MultiSwapPopularTokenResolver.tokens(marketKit: Self.stub(), for: Self.eth)

        #expect(ids(result) == ids([Self.usdtEth, Self.usdcEth, Self.usdtTron, Self.usdtBsc, Self.usdtBase, Self.btc, Self.xmr, Self.zec, Self.trx]))
    }

    @Test func bitcoinContextFallsBackToEthereumStable() {
        let result = MultiSwapPopularTokenResolver.tokens(marketKit: Self.stub(), for: Self.btc)

        #expect(result.first?.tokenQuery.id == Self.usdtEth.tokenQuery.id)
        #expect(!result.contains { $0.coin.uid == "bitcoin" })
    }

    @Test func nonNativeContextPutsChainNativeFirst() {
        let result = MultiSwapPopularTokenResolver.tokens(marketKit: Self.stub(), for: Self.usdtEth)

        #expect(result.first?.tokenQuery.id == Self.eth.tokenQuery.id)
        #expect(!result.contains { $0.coin.uid == "tether" && $0.blockchainType == .ethereum })
    }

    @Test func arbitrumContextKeepsOwnChainNative() {
        var stub = Self.stub()
        let ethArbitrum = Self.token(coinUid: "ethereum", blockchainType: .arbitrumOne)
        stub.tokensByQueryId[ethArbitrum.tokenQuery.id] = ethArbitrum
        let context = Self.token(coinUid: "usd-coin", blockchainType: .arbitrumOne, type: .eip20(address: "0xusdc-arb"))

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: context)

        #expect(result.first?.tokenQuery.id == ethArbitrum.tokenQuery.id)
        #expect(result.contains { $0.tokenQuery.id == Self.eth.tokenQuery.id })
    }

    @Test func runeNativeContextFallsBackToEthereumStable() {
        var stub = Self.stub()
        stub.tokensByQueryId[Self.rune.tokenQuery.id] = Self.rune

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: Self.rune)

        #expect(result.first?.tokenQuery.id == Self.usdtEth.tokenQuery.id)
    }

    @Test func thorChainAssetContextPutsRuneFirst() {
        var stub = Self.stub()
        stub.tokensByQueryId[Self.rune.tokenQuery.id] = Self.rune
        let context = Self.token(coinUid: "tcy", blockchainType: .thorChain, type: .unsupported(type: "thorchain", reference: "TCY"))

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: context)

        #expect(result.first?.tokenQuery.id == Self.rune.tokenQuery.id)
    }

    @Test func contextExcludesAllDerivationsOfSameCoinOnChain() {
        let context = Self.token(coinUid: "bitcoin", blockchainType: .bitcoin, type: .derived(derivation: .bip44))

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: Self.stub(), for: context)

        #expect(!result.contains { $0.coin.uid == "bitcoin" && $0.blockchainType == .bitcoin })
    }

    @Test(arguments: [nil, "eth", "btc", "usdtEth"]) func resultHasNoDuplicateIds(contextKey: String?) {
        let context: Token? = switch contextKey {
        case "eth": Self.eth
        case "btc": Self.btc
        case "usdtEth": Self.usdtEth
        default: nil
        }

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: Self.stub(), for: context)

        #expect(Set(ids(result)).count == result.count)
    }

    @Test func usdCoinDoesNotLeakIntoUsdtMap() {
        var stub = Self.stub()
        let usdcTron = Self.token(coinUid: "usd-coin", blockchainType: .tron, type: .eip20(address: "usdc-tron"))
        stub.coins = [
            FullCoin(coin: Self.usdtEth.coin, tokens: [Self.usdtEth, Self.usdtBsc, Self.usdtBase]),
            FullCoin(coin: Self.usdcEth.coin, tokens: [Self.usdcEth, usdcTron]),
        ]

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: Self.trx)

        #expect(result.first?.tokenQuery.id == Self.usdtEth.tokenQuery.id)
        #expect(result[1].tokenQuery.id == usdcTron.tokenQuery.id)
    }

    @Test func bscUsdtWinnerFollowsUidPriority() {
        var stub = Self.stub()
        let bridgedCoin = Coin(uid: "binance-bridged-usdt-bnb-smart-chain", name: "Bridged USDT", code: "USDT")
        let bridgedBsc = Token(
            coin: bridgedCoin,
            blockchain: Blockchain(type: .binanceSmartChain, name: "BSC", explorerUrl: nil),
            type: .eip20(address: "0xbridged"),
            decimals: 18
        )
        stub.coins.append(FullCoin(coin: bridgedCoin, tokens: [bridgedBsc]))
        let bnb = Self.token(coinUid: "binancecoin", blockchainType: .binanceSmartChain)

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: bnb)

        #expect(result.first?.coin.uid == "tether")
        #expect(result.first?.blockchainType == .binanceSmartChain)
    }

    @Test func nativesUnavailableDegradesToStables() {
        var stub = Self.stub()
        stub.tokensThrows = true

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: nil)

        #expect(ids(result) == ids([Self.usdtEth, Self.usdcEth, Self.usdtTron, Self.usdtBsc, Self.usdtBase]))
    }

    @Test func stablesUnavailableDegradesToNatives() {
        var stub = Self.stub()
        stub.fullCoinsThrows = true

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: nil)

        #expect(ids(result) == ids([Self.btc, Self.eth, Self.xmr, Self.zec, Self.trx]))
    }

    @Test func everythingUnavailableReturnsEmpty() {
        var stub = Self.stub()
        stub.tokensThrows = true
        stub.fullCoinsThrows = true
        stub.tokenThrows = true

        let result = MultiSwapPopularTokenResolver.tokens(marketKit: stub, for: Self.usdtEth)

        #expect(result.isEmpty)
    }

    private func ids(_ tokens: [Token]) -> [String] {
        tokens.map(\.tokenQuery.id)
    }
}

extension MultiSwapPopularTokenResolverTests {
    private static let btc = token(coinUid: "bitcoin", blockchainType: .bitcoin, type: .derived(derivation: .bip84))
    private static let eth = token(coinUid: "ethereum", blockchainType: .ethereum)
    private static let xmr = token(coinUid: "monero", blockchainType: .monero)
    private static let zec = token(coinUid: "zcash", blockchainType: .zcash)
    private static let trx = token(coinUid: "tron", blockchainType: .tron)
    private static let rune = token(coinUid: "thorchain", blockchainType: .thorChain)

    private static let usdtCoin = Coin(uid: "tether", name: "Tether", code: "USDT")
    private static let usdtEth = Token(coin: usdtCoin, blockchain: blockchain(.ethereum), type: .eip20(address: "0xusdt-eth"), decimals: 6)
    private static let usdtTron = Token(coin: usdtCoin, blockchain: blockchain(.tron), type: .eip20(address: "usdt-tron"), decimals: 6)
    private static let usdtBsc = Token(coin: usdtCoin, blockchain: blockchain(.binanceSmartChain), type: .eip20(address: "0xusdt-bsc"), decimals: 18)
    private static let usdtBase = Token(coin: usdtCoin, blockchain: blockchain(.base), type: .eip20(address: "0xusdt-base"), decimals: 6)

    private static let usdcCoin = Coin(uid: "usd-coin", name: "USD Coin", code: "USDC")
    private static let usdcEth = Token(coin: usdcCoin, blockchain: blockchain(.ethereum), type: .eip20(address: "0xusdc-eth"), decimals: 6)

    private static func stub() -> StubMarketKit {
        var stub = StubMarketKit()

        for token in [btc, eth, xmr, zec, trx] {
            stub.tokensByQueryId[token.tokenQuery.id] = token
        }

        stub.coins = [
            FullCoin(coin: usdtCoin, tokens: [usdtEth, usdtTron, usdtBsc, usdtBase]),
            FullCoin(coin: usdcCoin, tokens: [usdcEth]),
        ]

        return stub
    }

    private static func token(coinUid: String, blockchainType: BlockchainType, type: TokenType = .native, decimals: Int = 8) -> Token {
        Token(
            coin: Coin(uid: coinUid, name: coinUid, code: coinUid.uppercased()),
            blockchain: blockchain(blockchainType),
            type: type,
            decimals: decimals
        )
    }

    private static func blockchain(_ type: BlockchainType) -> Blockchain {
        Blockchain(type: type, name: type.uid, explorerUrl: nil)
    }

    private struct StubMarketKit: IMarketKit {
        var tokensByQueryId = [String: Token]()
        var coins = [FullCoin]()
        var tokenThrows = false
        var fullCoinsThrows = false
        var tokensThrows = false

        struct StubError: Error {}

        func token(query: TokenQuery) throws -> Token? {
            if tokenThrows {
                throw StubError()
            }
            return tokensByQueryId[query.id]
        }

        func fullCoins(coinUids: [String]) throws -> [FullCoin] {
            if fullCoinsThrows {
                throw StubError()
            }
            return coins.filter { coinUids.contains($0.coin.uid) }
        }

        func tokens(queries: [TokenQuery]) throws -> [Token] {
            if tokensThrows {
                throw StubError()
            }
            return queries.compactMap { tokensByQueryId[$0.id] }
        }
    }
}
