import Foundation

class WalletSorter {
    private let descending: (ISortableWalletItem, ISortableWalletItem) -> Bool = { lhsItem, rhsItem in
        let lhsBalance = lhsItem.balance
        let rhsBalance = rhsItem.balance
        let lhsHasPrice = lhsItem.priceItem != nil
        let rhsHasPrice = rhsItem.priceItem != nil

        if lhsHasPrice == rhsHasPrice {
            guard let lhsPrice = lhsItem.priceItem?.price.value, let rhsPrice = rhsItem.priceItem?.price.value else {
                return lhsBalance > rhsBalance
            }
            return lhsBalance * lhsPrice > rhsBalance * rhsPrice
        }

        return lhsHasPrice
    }

    func sort<Item: ISortableWalletItem>(items: [Item], sortType: SortType) -> [Item] {
        switch sortType {
        case .balance:
            let nonZeroItems = items.filter { !$0.balance.isZero }
            let zeroItems = items.filter(\.balance.isZero)

            return nonZeroItems.sorted(by: descending) + zeroItems.sorted(by: descending)
        case .name:
            return items.sorted { lhsItem, rhsItem in
                lhsItem.name.caseInsensitiveCompare(rhsItem.name) == .orderedAscending
            }
        case .percentGrowth:
            return items.sorted { lhsItem, rhsItem in
                guard let lhsDiff = lhsItem.diff, let rhsDiff = rhsItem.diff else {
                    return lhsItem.diff != nil
                }

                return lhsDiff > rhsDiff
            }
        }
    }
}

extension WalletSorter {
    enum SortType: String, CaseIterable {
        case balance
        case name
        case percentGrowth

        var title: String {
            switch self {
            case .balance: return "balance.sort.valueHighToLow".localized
            case .name: return "balance.sort.az".localized
            case .percentGrowth: return "balance.sort.price_change".localized
            }
        }
    }
}

protocol ISortableWalletItem: IComposableSortable {
    var balance: Decimal { get }
    var priceItem: WalletCoinPriceService.Item? { get }
    var name: String { get }
    var diff: Decimal? { get }
}

extension ISortableWalletItem {
    typealias Context = Void

    static func compare(_ lhs: Self, _ rhs: Self, by criterion: SortCriterion, context _: Void) -> ComparisonResult {
        switch criterion {
        case .nonZeroBalanceFirst:
            return Comparators.booleanFirst(!lhs.balance.isZero, !rhs.balance.isZero)

        case .hasPriceFirst:
            return Comparators.booleanFirst(lhs.priceItem != nil, rhs.priceItem != nil)

        case .fiatBalanceDescending:
            let l = (lhs.priceItem?.price.value ?? 0) * lhs.balance
            let r = (rhs.priceItem?.price.value ?? 0) * rhs.balance
            return Comparators.decimalDescending(l, r)

        case .balanceDescending:
            return Comparators.decimalDescending(lhs.balance, rhs.balance)

        case .nameAscending:
            return Comparators.stringAscending(lhs.name, rhs.name)

        case .percentGrowthDescending:
            return Comparators.optionalDecimalDescending(lhs.diff, rhs.diff)

        // Wallet items are always in active wallets by definition.
        case .enabled:
            return .orderedSame

        // Not exposed by ISortableWalletItem protocol.
        case .filterRelevance, .sameBlockchainFirst, .marketCapRank,
             .blockchainOrder, .tokenTypeOrder, .badge, .codeAscending, .codeNativeFirst:
            return .orderedSame
        }
    }
}
