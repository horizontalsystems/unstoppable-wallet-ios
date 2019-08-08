import Foundation

class BalanceSorter: IBalanceSorter {

    func sort(items: [BalanceItem], sort: BalanceSortType) -> [BalanceItem] {
        switch sort {
        case .value:
            return items.sorted { item, item2 in
                if item.rate == nil && item2.rate == nil {
                    return item.balance > item2.balance
                }

                return item.balance * (item.rate?.value ?? 0) > item2.balance * (item2.rate?.value ?? 0)
            }
        case .name:
            return items.sorted { item, item2 in
                item.wallet.coin.title.caseInsensitiveCompare(item2.wallet.coin.title) == .orderedAscending
            }
        case .manual:
            return items
        }
    }

}
