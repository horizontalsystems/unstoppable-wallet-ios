import Foundation

class WalletSorter {

    private let descending: (WalletService.Item, WalletService.Item) -> Bool = { lhsItem, rhsItem in
        let lhsBalance = lhsItem.balanceData.balance
        let rhsBalance = rhsItem.balanceData.balance
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

    func sort(items: [WalletService.Item], sortType: WalletModule.SortType) -> [WalletService.Item] {
        switch sortType {
        case .balance:
            let nonZeroItems = items.filter { !$0.balanceData.balance.isZero }
            let zeroItems = items.filter { $0.balanceData.balance.isZero }

            return nonZeroItems.sorted(by: descending) + zeroItems.sorted(by: descending)
        case .name:
            return items.sorted { lhsItem, rhsItem in
                lhsItem.element.name.caseInsensitiveCompare(rhsItem.element.name) == .orderedAscending
            }
        case .percentGrowth:
            return items.sorted { lhsItem, rhsItem in
                guard let lhsDiff = lhsItem.priceItem?.diff, let rhsDiff = rhsItem.priceItem?.diff else {
                    return lhsItem.priceItem?.diff != nil
                }

                return lhsDiff > rhsDiff
            }
        }
    }

}
