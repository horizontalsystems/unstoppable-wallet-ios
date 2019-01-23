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

    func handle(updatedItems: [TransactionItem], insertedItems: [TransactionItem]) {
        for item in updatedItems {
            items.removeAll { $0 == item }
        }

        items.append(contentsOf: updatedItems + insertedItems)

        items.sort()
        items.reverse()
    }

}
