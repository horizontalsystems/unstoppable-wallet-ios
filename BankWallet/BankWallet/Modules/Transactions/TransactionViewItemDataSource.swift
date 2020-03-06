import Foundation


class TransactionViewItemDataSource {
    var items = [TransactionViewItem]()

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

    func add(items: [TransactionViewItem]) {
        self.items.append(contentsOf: items)
    }

    func handle(newItems: [TransactionViewItem]) -> [TransactionViewItem] {
        for item in newItems {
            items.removeAll { $0 == item }
        }

        items.append(contentsOf: newItems)

        items.sort()
        items.reverse()

        return items
    }

}
