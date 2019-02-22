class TransactionItemDataSource {
    private var items = [TransactionItem]()

    var count: Int {
        return items.count
    }

    func item(forIndex index: Int) -> TransactionItem {
        return items[index]
    }

    func shouldInsert(record: TransactionRecord) -> Bool {
        if let lastItem = items.last {
            return lastItem.record.timestamp < record.timestamp
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

    func itemIndexes(coinCode: CoinCode, timestamp: Double) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if item.coinCode == coinCode && item.record.timestamp == timestamp {
                indexes.append(index)
            }
        }

        return indexes
    }

    func itemIndexes(coinCode: String, lastBlockHeight: Int, threshold: Int) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if let blockHeight = item.record.blockHeight, item.coinCode == coinCode && lastBlockHeight - blockHeight <= threshold {
                indexes.append(index)
            }
        }

        return indexes
    }

    func handle(updatedItems: [TransactionItem], insertedItems: [TransactionItem]) -> [IndexChange] {
        let oldItems = items

        for item in updatedItems {
            items.removeAll { $0 == item }
        }

        items.append(contentsOf: updatedItems)

        items.sort()
        items.reverse()

        var updated = [TransactionItem]()
        var moved = [(Int, TransactionItem)]()

        for item in updatedItems {
            if let oldIndex = oldItems.firstIndex(of: item), let index = items.firstIndex(of: item) {
                if oldIndex == index {
                    updated.append(item)
                } else {
                    moved.append((oldIndex, item))
                }
            }
        }

        items.append(contentsOf: insertedItems)

        items.sort()
        items.reverse()

        var changes = [IndexChange]()

        for updatedItem in updated {
            if let index = items.firstIndex(of: updatedItem) {
                changes.append(.update(index: index))
            }
        }

        for (oldIndex, movedItem) in moved {
            if let index = items.firstIndex(of: movedItem) {
                changes.append(.move(fromIndex: oldIndex, toIndex: index))
            }
        }

        for item in insertedItems {
            if let index = items.firstIndex(of: item) {
                changes.append(.insert(index: index))
            }
        }

        return changes
    }

}
