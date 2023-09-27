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

    func sort<Item: ISortableWalletItem>(items: [Item], sortType: WalletModule.SortType) -> [Item] {
        switch sortType {
        case .balance:
            let nonZeroItems = items.filter { !$0.balance.isZero }
            let zeroItems = items.filter { $0.balance.isZero }

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

protocol ISortableWalletItem {
    var balance: Decimal { get }
    var priceItem: WalletCoinPriceService.Item? { get }
    var name: String { get }
    var diff: Decimal? { get }
}

extension WalletService.Item: ISortableWalletItem {

    var balance: Decimal {
        balanceData.available
    }

    var name: String {
        element.name
    }

    var diff: Decimal? {
        priceItem?.diff
    }

}

extension WalletTokenListService.Item: ISortableWalletItem {

    var balance: Decimal {
        balanceData.available
    }

    var name: String {
        element.name
    }

    var diff: Decimal? {
        priceItem?.diff
    }

}
