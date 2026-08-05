import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

// default swap pair cascade per swap_default_state.md: explicit -> no wallets -> top wallet -> max fiat
struct MultiSwapDefaultPairResolverTests {
    @Test func noWalletsResolveToBitcoinMonero() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(hasWallets: false))

        #expect(pair.tokenIn == Self.btc)
        #expect(pair.tokenOut == Self.xmr)
    }

    @Test func allZeroBalancesPickTopWalletAndPopularZero() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: Self.usdtEth, balance: 0, price: 1),
                .init(token: Self.eth, balance: 0, price: 4000),
                .init(token: Self.btc, balance: 0, price: 100_000),
            ],
            popularTokens: { _ in [Self.usdtEth] }
        ))

        #expect(pair.tokenIn == Self.btc)
        #expect(pair.tokenOut == Self.usdtEth)
    }

    @Test func allZeroBalancesPreferPricedWallet() {
        let tokenX = Self.token(coinUid: "token-x", blockchainType: .solana, type: .spl(address: "xxx"))

        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: tokenX, balance: 0, price: nil),
                .init(token: Self.trx, balance: 0, price: 0.1),
            ],
            popularTokens: { _ in [Self.usdtEth] }
        ))

        #expect(pair.tokenIn == Self.trx)
    }

    @Test func singleFundedPricedItemWins() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [.init(token: Self.usdtEth, balance: 20.3, price: 1)],
            popularTokens: { _ in [Self.eth] }
        ))

        #expect(pair.tokenIn == Self.usdtEth)
        #expect(pair.tokenOut == Self.eth)
    }

    @Test func highestFiatBalanceWins() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: Self.usdtEth, balance: 1200, price: 1),
                .init(token: Self.eth, balance: 0.1, price: 4000),
                .init(token: Self.btc, balance: 0.0009, price: 100_000),
            ],
            popularTokens: { _ in [Self.eth] }
        ))

        #expect(pair.tokenIn == Self.usdtEth)
    }

    @Test func equalFiatTieBreakPrefersEthThenTronThenBsc() {
        let bnb = Self.token(coinUid: "binancecoin", blockchainType: .binanceSmartChain)
        let items: [MultiSwapDefaultPairResolver.Item] = [
            .init(token: bnb, balance: 1, price: 100),
            .init(token: Self.trx, balance: 1, price: 100),
            .init(token: Self.eth, balance: 1, price: 100),
        ]

        let full = MultiSwapDefaultPairResolver.resolve(Self.input(items: items))
        #expect(full.tokenIn == Self.eth)

        let withoutEth = MultiSwapDefaultPairResolver.resolve(Self.input(items: Array(items.prefix(2))))
        #expect(withoutEth.tokenIn == Self.trx)
    }

    @Test func equalFiatOutsidePriorityListFallsBackToBlockchainOrder() {
        let sol = Self.token(coinUid: "solana", blockchainType: .solana)
        let base = Self.token(coinUid: "base-eth", blockchainType: .base)

        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: base, balance: 1, price: 100),
                .init(token: sol, balance: 1, price: 100),
            ]
        ))

        #expect(pair.tokenIn == sol)
    }

    @Test func pricelessItemIgnoredEvenWithLargerBalance() {
        let tokenX = Self.token(coinUid: "token-x", blockchainType: .ethereum, type: .eip20(address: "0xx"))

        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: tokenX, balance: 5000, price: nil),
                .init(token: Self.eth, balance: 0.1, price: 4000),
            ],
            popularTokens: { _ in [Self.usdtEth] }
        ))

        #expect(pair.tokenIn == Self.eth)
        #expect(pair.tokenOut == Self.usdtEth)
    }

    @Test func allPricelessFundedFallBackToBitcoinMonero() {
        let tokenX = Self.token(coinUid: "token-x", blockchainType: .ethereum, type: .eip20(address: "0xx"))

        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [.init(token: tokenX, balance: 5000, price: nil)]
        ))

        #expect(pair.tokenIn == Self.btc)
        #expect(pair.tokenOut == Self.xmr)
    }

    @Test func zeroPriceTreatedAsNoPrice() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [.init(token: Self.eth, balance: 10, price: 0)]
        ))

        #expect(pair.tokenIn == Self.btc)
        #expect(pair.tokenOut == Self.xmr)
    }

    @Test func negativeBalanceTreatedAsZero() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: Self.eth, balance: -1, price: 4000),
                .init(token: Self.btc, balance: 0, price: 100_000),
            ],
            popularTokens: { _ in [Self.usdtEth] }
        ))

        #expect(pair.tokenIn == Self.btc)
    }

    @Test func dustBalanceCountsAsFunded() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [
                .init(token: Self.eth, balance: 0.000_000_01, price: 4000),
                .init(token: Self.btc, balance: 0, price: 100_000),
            ],
            popularTokens: { _ in [Self.usdtEth] }
        ))

        #expect(pair.tokenIn == Self.eth)
    }

    @Test func explicitTokenWinsOverWalletState() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            explicitToken: Self.usdtEth,
            items: [.init(token: Self.eth, balance: 100, price: 4000)],
            popularTokens: { context in context == Self.usdtEth ? [Self.eth] : [] }
        ))

        #expect(pair.tokenIn == Self.usdtEth)
        #expect(pair.tokenOut == Self.eth)
    }

    @Test func explicitWithoutAutoResolveLeavesDestinationNil() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            explicitToken: Self.usdtEth,
            autoResolveTokenOut: false
        ))

        #expect(pair.tokenIn == Self.usdtEth)
        #expect(pair.tokenOut == nil)
    }

    @Test func explicitBitcoinWithEmptyPopularFallsBackToMonero() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(explicitToken: Self.btc))

        #expect(pair.tokenOut == Self.xmr)
    }

    @Test func emptyPopularForNonBitcoinSourceFallsBackToBitcoin() {
        let pair = MultiSwapDefaultPairResolver.resolve(Self.input(
            items: [.init(token: Self.eth, balance: 1, price: 4000)]
        ))

        #expect(pair.tokenIn == Self.eth)
        #expect(pair.tokenOut == Self.btc)
    }

    @Test func missingBitcoinMoneroYieldNilPairWithoutCrash() {
        let pair = MultiSwapDefaultPairResolver.resolve(.init(
            explicitToken: nil,
            autoResolveTokenOut: true,
            hasWallets: false,
            items: [],
            popularTokens: { _ in [] },
            bitcoin: nil,
            monero: nil
        ))

        #expect(pair.tokenIn == nil)
        #expect(pair.tokenOut == nil)
    }
}

extension MultiSwapDefaultPairResolverTests {
    private static let btc = token(coinUid: "bitcoin", blockchainType: .bitcoin, type: .derived(derivation: .bip84))
    private static let eth = token(coinUid: "ethereum", blockchainType: .ethereum)
    private static let xmr = token(coinUid: "monero", blockchainType: .monero)
    private static let trx = token(coinUid: "tron", blockchainType: .tron)
    private static let usdtEth = token(coinUid: "tether", blockchainType: .ethereum, type: .eip20(address: "0xusdt"), decimals: 6)

    private static func input(
        explicitToken: Token? = nil,
        autoResolveTokenOut: Bool = true,
        hasWallets: Bool = true,
        items: [MultiSwapDefaultPairResolver.Item] = [],
        popularTokens: @escaping (Token?) -> [Token] = { _ in [] }
    ) -> MultiSwapDefaultPairResolver.Input {
        .init(
            explicitToken: explicitToken,
            autoResolveTokenOut: autoResolveTokenOut,
            hasWallets: hasWallets,
            items: items,
            popularTokens: popularTokens,
            bitcoin: btc,
            monero: xmr
        )
    }

    private static func token(coinUid: String, blockchainType: BlockchainType, type: TokenType = .native, decimals: Int = 8) -> Token {
        Token(
            coin: Coin(uid: coinUid, name: coinUid, code: coinUid.uppercased()),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: type,
            decimals: decimals
        )
    }
}
