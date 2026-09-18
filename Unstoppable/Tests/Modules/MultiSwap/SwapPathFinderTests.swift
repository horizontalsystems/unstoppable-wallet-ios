import Foundation
import MarketKit
import ObjectMapper
import SwiftUI
import Testing
@testable import Unstoppable
@testable import WalletCore

// Tier order (native first, then the hardcoded coin list) IS the ranking — the finder returns on
// the first hit.
struct SwapPathFinderTests {
    @Test func noCandidatesReturnsNil() {
        let finder = SwapPathFinder(candidateProviders: [])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: [Self.provider(edges: [])], suspensions: SwapSuspensionIndex()) == nil)
    }

    @Test func findsIntermediateViaNativeTier() throws {
        let providers = [Self.provider(id: "a", edges: [Self.edge(Self.eth, Self.sol), Self.edge(Self.sol, Self.bonk)])]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()))

        #expect(path.intermediateToken.tokenQuery.id == Self.sol.tokenQuery.id)
        #expect(path.tokenIn.tokenQuery.id == Self.eth.tokenQuery.id)
        #expect(path.tokenOut.tokenQuery.id == Self.bonk.tokenQuery.id)
    }

    @Test func nativeTierWinsOverCoinListTier() throws {
        let providers = [Self.provider(id: "a", edges: [
            Self.edge(Self.eth, Self.sol), Self.edge(Self.sol, Self.bonk),
            Self.edge(Self.eth, Self.usdtSol), Self.edge(Self.usdtSol, Self.bonk),
        ])]
        let finder = SwapPathFinder(candidateProviders: [
            Self.candidates([Self.sol]),
            Self.candidates([Self.usdtSol]),
        ])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()))

        #expect(path.intermediateToken.tokenQuery.id == Self.sol.tokenQuery.id)
    }

    @Test func tokenOutNativeTriedBeforeTokenInNative() throws {
        // Both natives link the pair; tokenOut's chain is the binding constraint, so SOL wins.
        let providers = [Self.provider(id: "a", edges: [
            Self.edge(Self.eth, Self.sol), Self.edge(Self.sol, Self.bonk),
            Self.edge(Self.eth, Self.trx), Self.edge(Self.trx, Self.bonk),
        ])]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol, Self.trx])])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()))

        #expect(path.intermediateToken.tokenQuery.id == Self.sol.tokenQuery.id)
    }

    @Test func legsMayUseDifferentProviders() {
        let providers = [
            Self.provider(id: "a", edges: [Self.edge(Self.eth, Self.sol)]),
            Self.provider(id: "b", edges: [Self.edge(Self.sol, Self.bonk)]),
        ]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()) != nil)
    }

    @Test func rejectsCandidateWithNoSecondLeg() {
        let providers = [Self.provider(id: "a", edges: [Self.edge(Self.eth, Self.sol)])]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()) == nil)
    }

    @Test func continuesToNextCandidateAfterRejectedOne() throws {
        // SOL has an inbound leg but no outbound one; the coin-list tier must still be reached.
        let providers = [Self.provider(id: "a", edges: [
            Self.edge(Self.eth, Self.sol),
            Self.edge(Self.eth, Self.usdtSol), Self.edge(Self.usdtSol, Self.bonk),
        ])]
        let finder = SwapPathFinder(candidateProviders: [
            Self.candidates([Self.sol]),
            Self.candidates([Self.usdtSol]),
        ])

        let path = try #require(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()))

        #expect(path.intermediateToken.tokenQuery.id == Self.usdtSol.tokenQuery.id)
    }

    @Test func skipsSecondLegWhenFirstLegEmpty() {
        let log = CallLog()
        let providers = [Self.provider(id: "a", edges: [Self.edge(Self.sol, Self.bonk)], log: log)]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])

        _ = finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex())

        #expect(log.calls == [Self.edge(Self.eth, Self.sol)])
    }

    @Test func respectsSuspensions() {
        // The one provider that could serve leg two is suspended for exactly that directed pair.
        let providers = [Self.provider(id: "a", edges: [Self.edge(Self.eth, Self.sol), Self.edge(Self.sol, Self.bonk)])]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])
        let suspensions = Self.suspensions(providerId: "a", sell: Self.sol, buy: Self.bonk)

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: suspensions) == nil)
    }

    @Test func suspendedProviderDoesNotCountTowardLeg() {
        let providers = [
            Self.provider(id: "a", edges: [Self.edge(Self.eth, Self.sol), Self.edge(Self.sol, Self.bonk)]),
            Self.provider(id: "b", edges: [Self.edge(Self.sol, Self.bonk)]),
        ]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.sol])])
        let suspensions = Self.suspensions(providerId: "a", sell: Self.sol, buy: Self.bonk)

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: suspensions) != nil)
    }

    @Test func skipsEndpointsAsCandidates() {
        let log = CallLog()
        let providers = [Self.provider(id: "a", edges: [Self.edge(Self.eth, Self.bonk)], log: log)]
        let finder = SwapPathFinder(candidateProviders: [Self.candidates([Self.eth, Self.bonk])])

        #expect(finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex()) == nil)
        #expect(log.calls.isEmpty)
    }

    @Test func deduplicatesAcrossTiers() {
        let log = CallLog()
        let providers = [Self.provider(id: "a", edges: [], log: log)]
        let finder = SwapPathFinder(candidateProviders: [
            Self.candidates([Self.sol]),
            Self.candidates([Self.sol]),
        ])

        _ = finder.find(tokenIn: Self.eth, tokenOut: Self.bonk, providers: providers, suspensions: SwapSuspensionIndex())

        #expect(log.calls == [Self.edge(Self.eth, Self.sol)])
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

    static func edge(_ from: Token, _ to: Token) -> String {
        "\(from.tokenQuery.id)>\(to.tokenQuery.id)"
    }

    static func provider(id: String = "stub", edges: [String], log: CallLog? = nil) -> IMultiSwapProvider {
        StubProvider(id: id, edges: Set(edges), log: log)
    }

    static func candidates(_ tokens: [Token]) -> ISwapPathCandidateProvider {
        StubCandidateProvider(tokens: tokens)
    }

    static func suspensions(providerId: String, sell: Token, buy: Token) -> SwapSuspensionIndex {
        let json: [String: Any] = [
            "kind": "pair",
            "sellAsset": CanonicalAssetId.of(token: sell) ?? "",
            "buyAsset": CanonicalAssetId.of(token: buy) ?? "",
        ]

        guard let suspension = try? SwapSuspension(JSON: json) else {
            return SwapSuspensionIndex()
        }

        return SwapSuspensionIndex(byProvider: [providerId: [suspension]])
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

    final class CallLog {
        private(set) var calls = [String]()

        func record(_ edge: String) {
            calls.append(edge)
        }
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

    private struct StubProvider: IMultiSwapProvider {
        let id: String
        let edges: Set<String>
        let log: CallLog?

        var name: String { id }
        var type: SwapProviderType { .good }
        var icon: String { "stub" }

        func supports(tokenIn: Token, tokenOut: Token) -> Bool {
            let edge = SwapPathFinderTests.edge(tokenIn, tokenOut)
            log?.record(edge)
            return edges.contains(edge)
        }

        func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> MultiSwapQuote {
            fatalError("not used")
        }

        func confirmationQuote(multiSwapQuote _: MultiSwapQuote, tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, slippage _: Decimal, recipient _: String?, transactionSettings _: TransactionSettings?) async throws -> SwapFinalQuote {
            fatalError("not used")
        }

        func preSwapView(step _: MultiSwapPreSwapStep, tokenIn _: Token, tokenOut _: Token, amount _: Decimal, isPresented _: Binding<Bool>, onSuccess _: @escaping () -> Void) -> AnyView {
            AnyView(EmptyView())
        }

        func track(swap: Swap) async throws -> Swap {
            swap
        }
    }
}
