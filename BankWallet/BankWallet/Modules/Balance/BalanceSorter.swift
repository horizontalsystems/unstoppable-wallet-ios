import Foundation

class BalanceSorter: IBalanceSorter {

    func sort(items: [BalanceItem], sort: BalanceSortType) -> [BalanceItem] {
        switch sort {
        case .value:
            guard items.allSatisfy({ $0.state == .synced }) else {
                return items
            }

            return items.sorted { item, item2 in
                guard let balance = item.balance, let balance2 = item2.balance else {
                    return item.balance != nil
                }

                guard let rate = item.marketInfo?.rate, let rate2 = item2.marketInfo?.rate else {
                    return balance > balance2
                }

                return balance * rate > balance2 * rate2
            }
        case .name:
            return items.sorted { item, item2 in
                item.wallet.coin.title.caseInsensitiveCompare(item2.wallet.coin.title) == .orderedAscending
            }
        case .percentGrowth:
            return items.sorted { item, item2 in
                guard let diff = item.marketInfo?.diff, let diff2 = item2.marketInfo?.diff else {
                    return item.marketInfo?.diff != nil
                }

                return diff > diff2
            }
        }
    }

}
