import Foundation

class BalanceSorter: IBalanceSorter {

    private let descending: ((BalanceItem, BalanceItem) -> Bool) = { item, item2 in
        let balance = item.balance ?? 0
        let balance2 = item2.balance ?? 0
        let hasRate = item.latestRate?.rate != nil
        let hasRate2 = item2.latestRate?.rate != nil

        if hasRate == hasRate2 {
            guard let rate = item.latestRate?.rate, let rate2 = item2.latestRate?.rate else {
                return balance > balance2
            }
            return balance * rate > balance2 * rate2
        }
        return hasRate
    }

    func sort(items: [BalanceItem], sort: SortType) -> [BalanceItem] {
        switch sort {
        case .value:
            let nonZeroItems = items.filter { !($0.balance ?? 0).isZero }
            let zeroItems = items.filter{ ($0.balance ?? 0).isZero }

            return nonZeroItems.sorted(by: descending) + zeroItems.sorted(by: descending)
        case .name:
            return items.sorted { item, item2 in
                item.wallet.coin.title.caseInsensitiveCompare(item2.wallet.coin.title) == .orderedAscending
            }
        case .percentGrowth:
            return items.sorted { item, item2 in
                guard let diff = item.latestRate?.rateDiff24h, let diff2 = item2.latestRate?.rateDiff24h else {
                    return item.latestRate?.rateDiff24h != nil
                }

                return diff > diff2
            }
        }
    }

}
