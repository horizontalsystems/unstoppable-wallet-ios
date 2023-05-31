import Foundation

class WalletSorter {

    private let descending: (IBalanceItem, IBalanceItem) -> Bool = { lhsBalanceItem, rhsBalanceItem in
        let lhsBalance = lhsBalanceItem.balanceData.balance
        let rhsBalance = rhsBalanceItem.balanceData.balance
        let lhsHasPrice = lhsBalanceItem.priceItem != nil
        let rhsHasPrice = rhsBalanceItem.priceItem != nil

        if lhsHasPrice == rhsHasPrice {
            guard let lhsPrice = lhsBalanceItem.priceItem?.price.value, let rhsPrice = rhsBalanceItem.priceItem?.price.value else {
                return lhsBalance > rhsBalance
            }
            return lhsBalance * lhsPrice > rhsBalance * rhsPrice
        }

        return lhsHasPrice
    }

    func sort<T: IBalanceItem>(balanceItems: [T], sortType: WalletModule.SortType) -> [T] {
        switch sortType {
        case .balance:
            let nonZeroItems = balanceItems.filter { !$0.balanceData.balance.isZero }
            let zeroItems = balanceItems.filter { $0.balanceData.balance.isZero }

            return nonZeroItems.sorted(by: descending) + zeroItems.sorted(by: descending)
        case .name:
            return balanceItems.sorted { lhsBalanceItem, rhsBalanceItem in
                lhsBalanceItem.item.coin.code.caseInsensitiveCompare(rhsBalanceItem.item.coin.code) == .orderedAscending
            }
        case .percentGrowth:
            return balanceItems.sorted { lhsBalanceItem, rhsBalanceItem in
                guard let lhsDiff = lhsBalanceItem.priceItem?.diff, let rhsDiff = rhsBalanceItem.priceItem?.diff else {
                    return lhsBalanceItem.priceItem?.diff != nil
                }

                return lhsDiff > rhsDiff
            }
        }
    }

}
