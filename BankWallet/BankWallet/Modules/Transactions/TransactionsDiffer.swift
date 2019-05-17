import DeepDiff

class TransactionsDiffer {
    var items: [TransactionItem]?

    func calculateDiff(for newItems: [TransactionItem]) -> [Change<TransactionItem>] {
        let oldItems = items ?? []
        items = newItems

        return diff(old: oldItems, new: newItems)
    }

}
