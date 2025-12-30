import Foundation
import MarketKit

class CoinSorter {
    static func sort(_ coins: [FullCoin], accountType: AccountType, options: [Option]) -> [FullCoin] {
        guard !options.isEmpty else { return coins }

        var prices: [String: Decimal]?
        if options.contains(.fiatValue) {
            prices = fetchPrices(coins, accountType: accountType)
        }

        return coins.sorted { lhs, rhs in
            for option in options {
                let comparison = compare(lhs: lhs, rhs: rhs, by: option, accountType: accountType, prices: prices)
                if comparison != .orderedSame {
                    return comparison == .orderedAscending
                }
            }
            return false
        }
    }

    private static func fetchPrices(_ coins: [FullCoin], accountType: AccountType) -> [String: Decimal] {
        let allTokens = coins.flatMap { $0.tokens.filter { accountType.supports(token: $0) } }
        let coinUids = Array(Set(allTokens.map(\.coin.uid)))

        let currency = Core.shared.currencyManager.baseCurrency
        let coinPriceMap = Core.shared.marketKit.coinPriceMap(coinUids: coinUids, currencyCode: currency.code)

        return coinPriceMap.compactMapValues { coinPrice -> Decimal? in
            coinPrice.expired ? nil : coinPrice.value
        }
    }

    private static func compare(lhs: FullCoin, rhs: FullCoin, by option: Option, accountType: AccountType, prices: [String: Decimal]?) -> ComparisonResult {
        switch option {
        case .fiatValue:
            return compareFiatValue(lhs: lhs, rhs: rhs, accountType: accountType, prices: prices)
        case .blockchain:
            return compareBlockchain(lhs: lhs, rhs: rhs, accountType: accountType)
        case let .relevance(filter):
            return compareRelevance(lhs: lhs, rhs: rhs, filter: filter)
        case .name:
            return compareName(lhs: lhs, rhs: rhs)
        }
    }

    private static func compareFiatValue(lhs: FullCoin, rhs: FullCoin, accountType: AccountType, prices: [String: Decimal]?) -> ComparisonResult {
        let lhsValue = calculateTotalFiatValue(fullCoin: lhs, accountType: accountType, prices: prices)
        let rhsValue = calculateTotalFiatValue(fullCoin: rhs, accountType: accountType, prices: prices)

        if lhsValue > rhsValue { return .orderedAscending }
        if lhsValue < rhsValue { return .orderedDescending }
        return .orderedSame
    }

    private static func compareBlockchain(lhs: FullCoin, rhs: FullCoin, accountType: AccountType) -> ComparisonResult {
        let lhsOrder = lhs.tokens.filter { accountType.supports(token: $0) }.first?.blockchainType.order ?? Int.max
        let rhsOrder = rhs.tokens.filter { accountType.supports(token: $0) }.first?.blockchainType.order ?? Int.max

        if lhsOrder < rhsOrder { return .orderedAscending }
        if lhsOrder > rhsOrder { return .orderedDescending }
        return .orderedSame
    }

    private static func compareRelevance(lhs: FullCoin, rhs: FullCoin, filter: String) -> ComparisonResult {
        let filter = filter.lowercased()

        let lhsExactCode = lhs.coin.code.lowercased() == filter
        let rhsExactCode = rhs.coin.code.lowercased() == filter
        if lhsExactCode != rhsExactCode {
            return lhsExactCode ? .orderedAscending : .orderedDescending
        }

        let lhsStartsWithCode = lhs.coin.code.lowercased().starts(with: filter)
        let rhsStartsWithCode = rhs.coin.code.lowercased().starts(with: filter)
        if lhsStartsWithCode != rhsStartsWithCode {
            return lhsStartsWithCode ? .orderedAscending : .orderedDescending
        }

        let lhsStartsWithName = lhs.coin.name.lowercased().starts(with: filter)
        let rhsStartsWithName = rhs.coin.name.lowercased().starts(with: filter)
        if lhsStartsWithName != rhsStartsWithName {
            return lhsStartsWithName ? .orderedAscending : .orderedDescending
        }

        return .orderedSame
    }

    private static func compareName(lhs: FullCoin, rhs: FullCoin) -> ComparisonResult {
        lhs.coin.name.lowercased().compare(rhs.coin.name.lowercased())
    }

    private static func calculateTotalFiatValue(fullCoin: FullCoin, accountType: AccountType, prices: [String: Decimal]?) -> Decimal {
        let eligibleTokens = fullCoin.tokens.filter { accountType.supports(token: $0) }
        let activeWallets = Core.shared.walletManager.activeWallets

        return eligibleTokens
            .compactMap { token in activeWallets.first { $0.token == token } }
            .map { wallet -> Decimal in
                let adapter = Core.shared.adapterManager.adapter(for: wallet) as? IBalanceAdapter
                let balance = adapter?.balanceData.available ?? 0
                return getFiatValue(token: wallet.token, balance: balance, prices: prices) ?? 0
            }
            .reduce(0, +)
    }

    private static func getFiatValue(token: Token, balance: Decimal, prices: [String: Decimal]?) -> Decimal? {
        guard let xRate = prices?[token.coin.uid] else { return nil }
        return xRate * balance
    }
}

extension CoinSorter {
    enum Option: Equatable {
        case fiatValue
        case blockchain
        case relevance(filter: String)
        case name
    }
}
