import Foundation

class WalletSorter {

    private let descending: (WalletService.Item, WalletService.Item) -> Bool = { item, item2 in
        let balance = item.balanceData.balance
        let balance2 = item2.balanceData.balance
        let hasRate = item.rateItem != nil
        let hasRate2 = item2.rateItem != nil

        if hasRate == hasRate2 {
            guard let rate = item.rateItem?.rate.value, let rate2 = item2.rateItem?.rate.value else {
                return balance > balance2
            }
            return balance * rate > balance2 * rate2
        }
        return hasRate
    }

    func sort(items: [WalletService.Item], sort: SortType) -> [WalletService.Item] {
        switch sort {
        case .value:
            let nonZeroItems = items.filter { !$0.balanceData.balance.isZero }
            let zeroItems = items.filter{ $0.balanceData.balance.isZero }

            return nonZeroItems.sorted(by: descending) + zeroItems.sorted(by: descending)
        case .name:
            return items.sorted { item, item2 in
                item.wallet.coin.code.caseInsensitiveCompare(item2.wallet.coin.code) == .orderedAscending
            }
        case .percentGrowth:
            return items.sorted { item, item2 in
                guard let diff = item.rateItem?.diff24h, let diff2 = item2.rateItem?.diff24h else {
                    return item.rateItem?.diff24h != nil
                }

                return diff > diff2
            }
        }
    }

}
