import Foundation

class WalletSorter {
    func sort<Item: ISortableWalletItem>(items: [Item], sortType: SortType) -> [Item] {
        items.sorted(by: criteria(for: sortType))
    }

    private func criteria(for sortType: SortType) -> [SortCriterion] {
        switch sortType {
        case .balance:
            return [.nonZeroBalanceFirst, .hasPriceFirst, .fiatBalanceDescending, .balanceDescending]
        case .name:
            return [.nameAscending]
        case .percentGrowth:
            return [.percentGrowthDescending]
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
