import Foundation
import MarketKit

/// One ordered source of intermediate-token candidates. `SwapPathFinder` walks its providers in
/// declared order and returns on the first candidate that links both legs — so the order in which a
/// provider returns its tokens *is* the priority.
protocol ISwapPathCandidateProvider {
    func candidates(tokenIn: Token, tokenOut: Token) -> [Token]
}

/// Tier 1: the native token of tokenOut's chain, then of tokenIn's chain.
///
/// tokenOut first on purpose — reaching the destination chain is the binding constraint
/// (for `ETH -> <SPL token>`, SOL is the gateway).
struct NativeSwapPathCandidateProvider: ISwapPathCandidateProvider {
    private let marketKit: IMarketKit

    init(marketKit: IMarketKit) {
        self.marketKit = marketKit
    }

    func candidates(tokenIn: Token, tokenOut: Token) -> [Token] {
        // defaultTokenQuery, not a raw `.native` query: BTC/LTC are derivation-based and BCH is
        // address-type-based, where `.native` resolves to nothing.
        var queries = [TokenQuery]()

        for query in [tokenOut.blockchainType.defaultTokenQuery, tokenIn.blockchainType.defaultTokenQuery] {
            if !queries.contains(where: { $0.id == query.id }) {
                queries.append(query)
            }
        }

        let tokens = (try? marketKit.tokens(queries: queries)) ?? []

        // tokens(queries:) does not promise input order — restore it.
        return queries.compactMap { query in
            tokens.first { $0.tokenQuery.id == query.id }
        }
    }
}

/// Tier 2: every chain deployment of a hardcoded list of coin uids.
struct CoinListSwapPathCandidateProvider: ISwapPathCandidateProvider {
    /// Product-defined bridge coins, in priority order.
    static let defaultCoinUids = ["tether", "usd-coin"]

    private static var unknownUidsLogged = false

    private let marketKit: IMarketKit
    private let coinUids: [String]

    init(marketKit: IMarketKit, coinUids: [String] = Self.defaultCoinUids) {
        self.marketKit = marketKit
        self.coinUids = coinUids
    }

    func candidates(tokenIn: Token, tokenOut: Token) -> [Token] {
        let fullCoins = (try? marketKit.fullCoins(coinUids: coinUids)) ?? []

        // Typo guard. Skipped while the local coin DB is still empty, as it is on a cold launch.
        if !Self.unknownUidsLogged, !fullCoins.isEmpty {
            let resolved = Set(fullCoins.map(\.coin.uid))
            let missing = coinUids.filter { !resolved.contains($0) }

            if !missing.isEmpty {
                Self.unknownUidsLogged = true
                print("SWAP PATH: coin uids unknown to MarketKit: \(missing)")
            }
        }

        let byUid = Dictionary(fullCoins.map { ($0.coin.uid, $0) }, uniquingKeysWith: { first, _ in first })

        // fullCoins(coinUids:) does not preserve input order — re-apply the configured priority.
        return coinUids.compactMap { byUid[$0] }.flatMap { fullCoin in
            sorted(tokens: fullCoin.tokens, tokenIn: tokenIn, tokenOut: tokenOut)
        }
    }

    // Within one coin: the deployment on tokenOut's chain first (for `ETH -> SPL` the USDT that
    // helps is USDT-on-Solana), then tokenIn's chain, then the rest in MarketKit order.
    private func sorted(tokens: [Token], tokenIn: Token, tokenOut: Token) -> [Token] {
        var outChain = [Token]()
        var inChain = [Token]()
        var rest = [Token]()

        for token in tokens {
            if token.blockchainType == tokenOut.blockchainType {
                outChain.append(token)
            } else if token.blockchainType == tokenIn.blockchainType {
                inChain.append(token)
            } else {
                rest.append(token)
            }
        }

        return outChain + inChain + rest
    }
}
