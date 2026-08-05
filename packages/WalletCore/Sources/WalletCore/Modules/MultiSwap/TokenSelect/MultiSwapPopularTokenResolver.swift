import MarketKit

protocol IMarketKit {
    func token(query: TokenQuery) throws -> Token?
    func fullCoins(coinUids: [String]) throws -> [FullCoin]
    func tokens(queries: [TokenQuery]) throws -> [Token]
}

extension MarketKit.Kit: IMarketKit {}

enum MultiSwapPopularTokenResolver {
    private static let baseNativeTypes: [BlockchainType] = [.bitcoin, .ethereum, .monero, .zcash, .tron]

    // priority order: first uid that has a token on a chain becomes that chain's USDT
    private static let usdtUids = [
        "tether",
        "polygon-bridged-usdt-polygon",
        "binance-bridged-usdt-bnb-smart-chain",
        "l2-standard-bridged-usdt-base",
        "arbitrum-bridged-usdt-arbitrum",
    ]

    private static let usdcUid = "usd-coin"

    static func tokens(for context: Token?) -> [Token] {
        tokens(marketKit: Core.shared.marketKit, for: context)
    }

    static func tokens(marketKit: IMarketKit, for context: Token?) -> [Token] {
        let nativeTokens = (try? marketKit.tokens(queries: baseNativeTypes.map(\.defaultTokenQuery))) ?? []
        let baseNatives: [Token?] = baseNativeTypes.map { type in
            nativeTokens.first { $0.tokenQuery.id == type.defaultTokenQuery.id }
        }

        let usdtPriority = Dictionary(uniqueKeysWithValues: usdtUids.enumerated().map { ($1, $0) })
        let stableCoins = (try? marketKit.fullCoins(coinUids: usdtUids + [usdcUid])) ?? []

        let usdt = Dictionary(
            grouping: stableCoins
                .filter { usdtPriority[$0.coin.uid] != nil }
                .sorted { (usdtPriority[$0.coin.uid] ?? .max) < (usdtPriority[$1.coin.uid] ?? .max) }
                .flatMap(\.tokens),
            by: \.blockchainType
        ).compactMapValues(\.first)

        let usdc = Dictionary(
            grouping: stableCoins.first { $0.coin.uid == usdcUid }?.tokens ?? [],
            by: \.blockchainType
        ).compactMapValues(\.first)

        let usdtEth = usdt[.ethereum]
        let usdcEth = usdc[.ethereum]
        let tailStables = [usdtEth, usdt[.tron], usdt[.binanceSmartChain], usdt[.base]]

        let ordered: [Token?]
        switch context {
        case nil:
            ordered = baseNatives + [usdtEth, usdcEth] + tailStables
        case let context? where context.type.isNative:
            let usdtSame = usdt[context.blockchainType] ?? usdtEth
            let usdcSame = usdc[context.blockchainType] ?? usdcEth
            ordered = [usdtSame, usdcSame] + tailStables + baseNatives
        case let context?:
            let nativeSame = (try? marketKit.token(query: context.blockchainType.defaultTokenQuery)) ?? nil
            let usdtSame = usdt[context.blockchainType] ?? usdtEth
            let usdcSame = usdc[context.blockchainType] ?? usdcEth
            ordered = [nativeSame] + baseNatives + [usdtSame, usdcSame] + tailStables
        }

        var seenIds = Set<String>()
        var result = [Token]()

        for case let token? in ordered {
            // can't swap into the context token itself; any derivation of the coin counts
            if let context, token.coin.uid == context.coin.uid, token.blockchainType == context.blockchainType {
                continue
            }
            guard seenIds.insert(token.tokenQuery.id).inserted else {
                continue
            }
            result.append(token)
        }

        return result
    }
}
