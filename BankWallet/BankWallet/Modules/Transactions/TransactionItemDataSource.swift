import Foundation


class TransactionItemDataSource {
    var items = [TransactionItem]()

    var count: Int {
        items.count
    }

    func item(forIndex index: Int) -> TransactionItem {
        items[index]
    }

    func shouldInsert(record: TransactionRecord) -> Bool {
        if let lastItem = items.last {
            return lastItem.record < record
        } else {
            return true
        }
    }

    func clear() {
        items = []
    }

    func add(items: [TransactionItem]) {
        self.items.append(contentsOf: items)
    }

    func itemIndexes(coin: Coin, date: Date) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if item.wallet.coin == coin && item.record.date == date {
                indexes.append(index)
            }
        }

        return indexes
    }

    func recordIndexes(greaterThan thresholdBlockHeight: Int, wallet: Wallet) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if let blockHeight = item.record.blockHeight, item.wallet == wallet && blockHeight > thresholdBlockHeight {
                indexes.append(index)
            } else if item.record.blockHeight == nil {
                indexes.append(index)
            }
        }

        return indexes
    }

    func recordIndexes(unlockingBefore blockTimestamp: Int, oldBlockTimestamp: Int?, wallet: Wallet) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if let lockTime = item.record.lockInfo?.lockedUntil.timeIntervalSince1970,
               lockTime > Double(oldBlockTimestamp ?? 0),
               lockTime <= Double(blockTimestamp),
               item.wallet == wallet {
                indexes.append(index)
            }
        }

        return indexes
    }

    func handle(newItems: [TransactionItem]) -> [TransactionItem] {
        for item in newItems {
            items.removeAll { $0 == item }
        }

        items.append(contentsOf: newItems)

        items.sort()
        items.reverse()

        return items
    }

}
