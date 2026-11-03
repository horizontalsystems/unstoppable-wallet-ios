import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

/// Tier order (native first, then the hardcoded coin list) IS the ranking — the finder returns on
/// the first catalogued hit.
struct SwapPathFinderTests {
    @Test func noCandidatesReturnsNil() {
        let finder = SwapPathFinder(candidateProviders: [])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: { _ in true }) == nil)
    }

    @Test func findsIntermediateViaNativeTier() throws {
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: Self.known([Self.sol])))

        #expect(path.intermediateToken.tokenQuery.id == Self.sol.tokenQuery.id)
        #expect(path.tokenIn.tokenQuery.id == Self.eth.tokenQuery.id)
        #expect(path.tokenOut.tokenQuery.id == Self.bonk.tokenQuery.id)
    }

    @Test func nativeTierWinsOverCoinListTier() throws {
        let finder = SwapPathFinder(candidateProviders: [
            Self.candidates([Self.sol]),
            Self.candidates([Self.usdtSol]),
        ])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: Self.known([Self.sol, Self.usdtSol])))

        #expect(path.intermediateToken.tokenQuery.id == Self.sol.tokenQuery.id)
    }

    @Test func tokenOutNativeTriedBeforeTokenInNative() throws {
        // Both natives are catalogued; tokenOut's chain is the binding constraint, so SOL wins.
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol, Self.trx])])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: Self.known([Self.sol, Self.trx])))

        #expect(path.intermediateToken.tokenQuery.id == Self.sol.tokenQuery.id)
    }

    @Test func rejectsUncataloguedCandidate() {
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: Self.known([])) == nil)
    }

    @Test func continuesToNextCandidateAfterRejectedOne() throws {
        // SOL is not catalogued; the coin-list tier must still be reached.
        let finder = SwapPathFinder(candidateProviders: [
            Self.candidates([Self.sol]),
            Self.candidates([Self.usdtSol]),
        ])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: Self.known([Self.usdtSol])))

        #expect(path.intermediateToken.tokenQuery.id == Self.usdtSol.tokenQuery.id)
    }

    @Test func skipsEndpointsAsCandidates() {
        var asked = [String]()
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.eth, Self.bonk])])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: { asked.append($0.tokenQuery.id); return true }) == nil)
        #expect(asked.isEmpty)
    }

    @Test func deduplicatesAcrossTiers() {
        var asked = [String]()
        let finder = SwapPathFinder(candidateProviders: [
            Self.candidates([Self.sol]),
            Self.candidates([Self.sol]),
        ])

        _ = finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, isKnown: { asked.append($0.tokenQuery.id); return false })

        #expect(asked == [Self.sol.tokenQuery.id])
    }
}

// MARK: - Candidate providers

struct SwapPathCandidateProviderTests {
    @Test func nativeTierReturnsTokenOutChainFirst() {
        let provider = NativeSwapPathCandidateProvider(marketKit: SwapPathFinderTests.stubMarketKit())

        let candidates = provider.candidates(tokenIn: SwapPathFinderTests.eth, tokenOut: SwapPathFinderTests.bonk)

        #expect(candidates.map(\.tokenQuery.id) == [SwapPathFinderTests.sol, SwapPathFinderTests.eth].map(\.tokenQuery.id))
    }

    @Test func nativeTierCollapsesWhenChainsMatch() {
        let provider = NativeSwapPathCandidateProvider(marketKit: SwapPathFinderTests.stubMarketKit())

        let candidates = provider.candidates(tokenIn: SwapPathFinderTests.eth, tokenOut: SwapPathFinderTests.usdtEth)

        #expect(candidates.map(\.tokenQuery.id) == [SwapPathFinderTests.eth.tokenQuery.id])
    }

    @Test func nativeTierDropsUnknownChain() {
        var stub = SwapPathFinderTests.stubMarketKit()
        stub.tokensByQueryId.removeValue(forKey: SwapPathFinderTests.sol.tokenQuery.id)
        let provider = NativeSwapPathCandidateProvider(marketKit: stub)

        let candidates = provider.candidates(tokenIn: SwapPathFinderTests.eth, tokenOut: SwapPathFinderTests.bonk)

        #expect(candidates.map(\.tokenQuery.id) == [SwapPathFinderTests.eth.tokenQuery.id])
    }

    @Test func coinListTierKeepsConfiguredUidOrderAndSortsChains() {
        var stub = SwapPathFinderTests.stubMarketKit()
        // returned in the opposite order on purpose: fullCoins(coinUids:) makes no order promise
        stub.coins = [
            FullCoin(coin: SwapPathFinderTests.usdcCoin, tokens: [SwapPathFinderTests.usdcEth]),
            FullCoin(coin: SwapPathFinderTests.usdtCoin, tokens: [SwapPathFinderTests.usdtTron, SwapPathFinderTests.usdtEth, SwapPathFinderTests.usdtSol]),
        ]
        let provider = CoinListSwapPathCandidateProvider(marketKit: stub, coinUids: ["tether", "usd-coin"])

        let candidates = provider.candidates(tokenIn: SwapPathFinderTests.eth, tokenOut: SwapPathFinderTests.bonk)

        #expect(candidates.map(\.tokenQuery.id) == [
            SwapPathFinderTests.usdtSol, SwapPathFinderTests.usdtEth, SwapPathFinderTests.usdtTron, SwapPathFinderTests.usdcEth,
        ].map(\.tokenQuery.id))
    }

    @Test func coinListTierIgnoresUnknownUid() {
        let provider = CoinListSwapPathCandidateProvider(marketKit: SwapPathFinderTests.stubMarketKit(), coinUids: ["nope", "usd-coin"])

        let candidates = provider.candidates(tokenIn: SwapPathFinderTests.eth, tokenOut: SwapPathFinderTests.bonk)

        #expect(candidates.map(\.tokenQuery.id) == [SwapPathFinderTests.usdcEth.tokenQuery.id])
    }

    @Test func coinListTierDegradesToEmptyWhenLookupFails() {
        var stub = SwapPathFinderTests.stubMarketKit()
        stub.fullCoinsThrows = true
        let provider = CoinListSwapPathCandidateProvider(marketKit: stub, coinUids: ["tether"])

        #expect(provider.candidates(tokenIn: SwapPathFinderTests.eth, tokenOut: SwapPathFinderTests.bonk).isEmpty)
    }
}

// MARK: - Fixtures

extension SwapPathFinderTests {
    static let eth = token(coinUid: "ethereum", blockchainType: .ethereum)
    static let sol = token(coinUid: "solana", blockchainType: .solana)
    static let trx = token(coinUid: "tron", blockchainType: .tron)
    static let bonk = token(coinUid: "bonk", blockchainType: .solana, type: .spl(address: "bonk-mint"))

    static let usdtCoin = Coin(uid: "tether", name: "Tether", code: "USDT")
    static let usdtEth = Token(coin: usdtCoin, blockchain: blockchain(.ethereum), type: .eip20(address: "0xusdt-eth"), decimals: 6)
    static let usdtTron = Token(coin: usdtCoin, blockchain: blockchain(.tron), type: .eip20(address: "usdt-tron"), decimals: 6)
    static let usdtSol = Token(coin: usdtCoin, blockchain: blockchain(.solana), type: .spl(address: "usdt-sol"), decimals: 6)

    static let usdcCoin = Coin(uid: "usd-coin", name: "USD Coin", code: "USDC")
    static let usdcEth = Token(coin: usdcCoin, blockchain: blockchain(.ethereum), type: .eip20(address: "0xusdc-eth"), decimals: 6)

    static func token(coinUid: String, blockchainType: BlockchainType, type: TokenType = .native, decimals: Int = 8) -> Token {
        Token(
            coin: Coin(uid: coinUid, name: coinUid, code: coinUid.uppercased()),
            blockchain: blockchain(blockchainType),
            type: type,
            decimals: decimals
        )
    }

    static func blockchain(_ type: BlockchainType) -> Blockchain {
        Blockchain(type: type, name: type.uid, explorerUrl: nil)
    }

    static func candidates(_ tokens: [Token]) -> ISwapPathCandidateProvider {
        StubCandidateProvider(tokens: tokens)
    }

    /// Catalog membership as a set of token query ids
    static func known(_ tokens: [Token]) -> (Token) -> Bool {
        let ids = Set(tokens.map(\.tokenQuery.id))
        return { ids.contains($0.tokenQuery.id) }
    }

    static func stubMarketKit() -> StubMarketKit {
        var stub = StubMarketKit()

        for token in [eth, sol, trx] {
            stub.tokensByQueryId[token.tokenQuery.id] = token
        }

        stub.coins = [
            FullCoin(coin: usdtCoin, tokens: [usdtEth, usdtTron, usdtSol]),
            FullCoin(coin: usdcCoin, tokens: [usdcEth]),
        ]

        return stub
    }

    struct StubMarketKit: IMarketKit {
        var tokensByQueryId = [String: Token]()
        var coins = [FullCoin]()
        var fullCoinsThrows = false

        struct StubError: Error {}

        func token(query: TokenQuery) throws -> Token? {
            tokensByQueryId[query.id]
        }

        func fullCoins(coinUids: [String]) throws -> [FullCoin] {
            if fullCoinsThrows {
                throw StubError()
            }
            return coins.filter { coinUids.contains($0.coin.uid) }
        }

        func tokens(queries: [TokenQuery]) throws -> [Token] {
            // deliberately reversed: the provider must restore the requested order itself
            queries.reversed().compactMap { tokensByQueryId[$0.id] }
        }
    }

    private struct StubCandidateProvider: ISwapPathCandidateProvider {
        let tokens: [Token]

        func candidates(tokenIn _: Token, tokenOut _: Token) -> [Token] {
            tokens
        }
    }
}
