import Foundation

class WalletSorter {
    func sort<Item: ISortableWalletItem>(items: [Item], sortType: SortType) -> [Item] {
        items.sorted(by: criteria(for: sortType))
    }

    private func criteria(for sortType: SortType) -> [SortCriterion] {
        switch sortType {
        case .balance:
            return SortCriterion.walletBalance
        case .name:
            return SortCriterion.walletName
        case .percentGrowth:
            return SortCriterion.walletPercentGrowth
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

protocol ISortableWalletItem: IComposableSortable where Context == Void {
    var balance: Decimal { get }
    var priceItem: WalletCoinPriceService.Item? { get }
    var name: String { get }
    var diff: Decimal? { get }
}
