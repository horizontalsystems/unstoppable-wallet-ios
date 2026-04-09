import Foundation
import MarketKit

// Marker protocol for types that carry a Coin. Enables sharing coin-level
// comparison logic between Token and FullCoin.
private protocol ICoinProvider {
    var coin: Coin { get }
}

extension Token: ICoinProvider {}
extension FullCoin: ICoinProvider {}

// Shared comparison logic for criteria that read only from Coin fields.
// Applicable to any ICoinProvider-conforming type. Both Token and FullCoin delegate
// these cases via their compare(...) switch.
private func compareByCoin<T: ICoinProvider>(_ lhs: T, _ rhs: T, by criterion: SortCriterion, filter: String) -> ComparisonResult {
    switch criterion {
    // Search relevance: exact code match -> code prefix match -> name prefix match.
    case .filterRelevance:
        return Comparators.filterRelevance(
            lhsCode: lhs.coin.code, lhsName: lhs.coin.name,
            rhsCode: rhs.coin.code, rhsName: rhs.coin.name,
            filter: filter
        )

    // Sort by coin market cap rank ascending. nil ranks sort last.
    case .marketCapRank:
        return Comparators.optionalIntAscending(lhs.coin.marketCapRank, rhs.coin.marketCapRank)

    // Sort by coin code alphabetically. Codes are stored uppercased so raw < is safe.
    case .codeAscending:
        return Comparators.rawStringAscending(lhs.coin.code, rhs.coin.code)

    // Sort by coin name alphabetically, case-insensitive.
    case .nameAscending:
        return Comparators.stringAscending(lhs.coin.name, rhs.coin.name)

    default:
        return .orderedSame
    }
}

extension Token: IComposableSortable {
    typealias Context = TokenSortContext

    static func compare(_ lhs: Token, _ rhs: Token, by criterion: SortCriterion, context: TokenSortContext) -> ComparisonResult {
        switch criterion {
        // Shared coin-level comparisons handled by compareByCoin above.
        case .filterRelevance, .marketCapRank, .codeAscending, .nameAscending:
            return compareByCoin(lhs, rhs, by: criterion, filter: context.filter)

        // Tokens present in the user's active wallets come first.
        case .enabled:
            return Comparators.booleanFirst(
                context.enabledTokens.contains(lhs),
                context.enabledTokens.contains(rhs)
            )

        // Tokens on the same blockchain as the reference token come first.
        // Used in the swap flow to prefer the "from-token" chain when offering the counterpart.
        case .sameBlockchainFirst:
            guard let ref = context.referenceToken else { return .orderedSame }
            return Comparators.booleanFirst(
                lhs.blockchainType == ref.blockchainType,
                rhs.blockchainType == ref.blockchainType
            )

        // Sort by fiat value (balance * price), highest first.
        // Values are precomputed in TokenSortContext.init and stored in the shared fiatValues
        // dictionary keyed by token.tokenQuery.id.
        case .fiatBalanceDescending:
            return Comparators.decimalDescending(
                context.fiatValues[lhs.tokenQuery.id] ?? 0,
                context.fiatValues[rhs.tokenQuery.id] ?? 0
            )

        // Sort by raw token balance, highest first.
        case .balanceDescending:
            return Comparators.decimalDescending(
                context.balances[lhs] ?? 0,
                context.balances[rhs] ?? 0
            )

        // Tokens with non-zero balance come before zero-balance (or missing) ones.
        case .nonZeroBalanceFirst:
            return Comparators.booleanFirst(
                !(context.balances[lhs] ?? 0).isZero,
                !(context.balances[rhs] ?? 0).isZero
            )

        // Sort by blockchain display order (BTC -> ETH -> BSC -> ...), most prominent first.
        case .blockchainOrder:
            return Comparators.intAscending(lhs.blockchainType.order, rhs.blockchainType.order)

        // Sort by token type display order (native -> eip20 -> bep20 -> ...).
        case .tokenTypeOrder:
            return Comparators.intAscending(lhs.type.order, rhs.type.order)

        // Sort by badge string alphabetically. Disambiguates tokens of the same coin on the same chain.
        case .badge:
            return Comparators.stringAscending(lhs.badge ?? "", rhs.badge ?? "")

        // Disambiguator for same-code tokens on different blockchains:
        // prefer the native token over wrapped/bridged variants.
        // e.g. BNB native on BSC beats BNB BEP20 wrapped on Ethereum.
        // Returns .orderedSame when codes differ, blockchains match, or both sides are (non-)native.
        case .codeNativeFirst:
            if lhs.coin.code != rhs.coin.code { return .orderedSame }
            if lhs.blockchainType == rhs.blockchainType { return .orderedSame }
            let lhsNative: Bool = { if case .native = lhs.type { return true } else { return false } }()
            let rhsNative: Bool = { if case .native = rhs.type { return true } else { return false } }()
            return Comparators.booleanFirst(lhsNative, rhsNative)

        // Tokens with a known price come before tokens without.
        // Uses fiatValues presence as a proxy: both TokenSortContext inits populate an entry
        // only when a price was available at build time.
        case .hasPriceFirst:
            return Comparators.booleanFirst(
                context.fiatValues[lhs.tokenQuery.id] != nil,
                context.fiatValues[rhs.tokenQuery.id] != nil
            )

        // Not needed by Token in current modules. No module sorts tokens by 24h price change at the
        // token level — TokenSortContext doesn't carry a priceChanges dictionary.
        case .percentGrowthDescending:
            return .orderedSame
        }
    }
}

extension FullCoin: IComposableSortable {
    typealias Context = FullCoinSortContext

    static func compare(_ lhs: FullCoin, _ rhs: FullCoin, by criterion: SortCriterion, context: FullCoinSortContext) -> ComparisonResult {
        switch criterion {
        // Shared coin-level comparisons handled by compareByCoin above.
        case .filterRelevance, .marketCapRank, .codeAscending, .nameAscending:
            return compareByCoin(lhs, rhs, by: criterion, filter: context.filter)

        // Coins with at least one token in the user's active wallets come first.
        case .enabled:
            return Comparators.booleanFirst(
                lhs.tokens.contains { context.enabledTokens.contains($0) },
                rhs.tokens.contains { context.enabledTokens.contains($0) }
            )

        // Sort by aggregated fiat value across all supported tokens of this coin, highest first.
        // Values are precomputed in FullCoinSortContext.init and stored in the shared fiatValues
        // dictionary keyed by coin.uid.
        case .fiatBalanceDescending:
            return Comparators.decimalDescending(
                context.fiatValues[lhs.coin.uid] ?? 0,
                context.fiatValues[rhs.coin.uid] ?? 0
            )

        // Sort by blockchain display order using the first supported token of each coin.
        // "Supported" is determined by the active account type. Falls back to the first token if no
        // accountType is provided. Matches the legacy CoinSorter behavior for the Receive coin list.
        case .blockchainOrder:
            let lhsOrder = firstSupportedBlockchainOrder(fullCoin: lhs, accountType: context.accountType)
            let rhsOrder = firstSupportedBlockchainOrder(fullCoin: rhs, accountType: context.accountType)
            return Comparators.intAscending(lhsOrder, rhsOrder)

        // Coins with a known price come before coins without.
        // Uses fiatValues presence as a proxy: FullCoinSortContext.init only adds an entry
        // when the coin's price was available at build time.
        case .hasPriceFirst:
            return Comparators.booleanFirst(
                context.fiatValues[lhs.coin.uid] != nil,
                context.fiatValues[rhs.coin.uid] != nil
            )

        // Disambiguator for multiple FullCoins sharing the same coin.code (e.g. ZEC native on
        // Zcash, ZEC BEP20 on BSC, ZEC wrapped on Solana are often three distinct Coin uids
        // with identical code). The one containing at least one native-type token wins.
        // Returns .orderedSame when codes differ or both sides contain (or lack) a native token.
        case .codeNativeFirst:
            if lhs.coin.code != rhs.coin.code { return .orderedSame }
            let lhsHasNative = lhs.tokens.contains {
                if case .native = $0.type { return true } else { return false }
            }
            let rhsHasNative = rhs.tokens.contains {
                if case .native = $0.type { return true } else { return false }
            }
            return Comparators.booleanFirst(lhsHasNative, rhsHasNative)

        // Genuinely inapplicable for FullCoin: a coin aggregates multiple tokens with potentially
        // different badges, token types, and blockchain affinities, so there is no canonical value
        // to sort by.
        case .badge, .tokenTypeOrder, .sameBlockchainFirst:
            return .orderedSame

        // Not exposed for FullCoin: per-token balance fields live outside this context and the
        // aggregated fiat value is already available via fiatValues above.
        case .balanceDescending, .percentGrowthDescending, .nonZeroBalanceFirst:
            return .orderedSame
        }
    }

    // Returns the blockchain display order of the first token the current account type supports.
    // If accountType is nil, falls back to the first token in the coin's tokens list.
    // Returns Int.max when no token matches, so unsupported coins sort last.
    private static func firstSupportedBlockchainOrder(fullCoin: FullCoin, accountType: AccountType?) -> Int {
        if let accountType {
            return fullCoin.tokens.first { accountType.supports(token: $0) }?.blockchainType.order ?? .max
        }
        return fullCoin.tokens.first?.blockchainType.order ?? .max
    }
}
