import Foundation
import DeepDiff

class TransactionItemDataSource {
    var items = [TransactionItem]()

    var count: Int {
        return items.count
    }

    func item(forIndex index: Int) -> TransactionItem {
        return items[index]
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
            if item.coin == coin && item.record.date == date {
                indexes.append(index)
            }
        }

        return indexes
    }

    func recordIndexes(greaterThan thresholdBlockHeight: Int, coin: Coin) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if let blockHeight = item.record.blockHeight, item.coin == coin && blockHeight > thresholdBlockHeight {
                indexes.append(index)
            } else if item.record.blockHeight == nil {
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
