import Foundation

class WalletSorter {

    private let descending: (WalletService.Item, WalletService.Item) -> Bool = { item, item2 in
        let balance = item.balanceData.balance
        let balance2 = item2.balanceData.balance
        let hasPrice = item.priceItem != nil
        let hasPrice2 = item2.priceItem != nil

        if hasPrice == hasPrice2 {
            guard let price = item.priceItem?.price.value, let price2 = item2.priceItem?.price.value else {
                return balance > balance2
            }
            return balance * price > balance2 * price2
        }
        return hasPrice
    }

    func sort(items: [WalletService.Item], sortType: WalletModule.SortType) -> [WalletService.Item] {
        switch sortType {
        case .balance:
            let nonZeroItems = items.filter { !$0.balanceData.balance.isZero }
            let zeroItems = items.filter { $0.balanceData.balance.isZero }

            return nonZeroItems.sorted(by: descending) + zeroItems.sorted(by: descending)
        case .name:
            return items.sorted { item, item2 in
                item.wallet.coin.code.caseInsensitiveCompare(item2.wallet.coin.code) == .orderedAscending
            }
        case .percentGrowth:
            return items.sorted { item, item2 in
                guard let diff = item.priceItem?.diff, let diff2 = item2.priceItem?.diff else {
                    return item.priceItem?.diff != nil
                }

                return diff > diff2
            }
        }
    }

}
