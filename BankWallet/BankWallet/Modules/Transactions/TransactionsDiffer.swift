import DeepDiff

class TransactionsDiffer {
    let queue: DispatchQueue
    let state: TransactionsDifferState

    weak var viewItemDelegate: ITransactionViewItemDataSourceDelegate?

    init(state: TransactionsDifferState, async: Bool = true) {
        self.state = state
        queue = async ? DispatchQueue.global(qos: .userInteractive) : DispatchQueue.main
    }

}

extension TransactionsDiffer: ITransactionViewItemDataSource {

    func reload(with newItems: [TransactionItem], animated: Bool) {
        queue.sync {
            var newViewItems = state.viewItems ?? []
            let itemsChanges = IndexPathConverter().convert(changes: diff(old: state.items, new: newItems), section: 0)

            for index in itemsChanges.deletes.sorted().reversed() {
                newViewItems.remove(at: index.row)
            }
            for index in itemsChanges.inserts {
                if let viewItem = viewItemDelegate?.createViewItem(for: newItems[index.row]) {
                    newViewItems.insert(viewItem, at: index.row)
                }
            }
            var updateIndexes = itemsChanges.moves.reduce([Int]()) {
                var updates = $0
                updates.append($1.from.row)
                updates.append($1.to.row)
                return updates
            }
            updateIndexes.append(contentsOf: itemsChanges.replaces.map { $0.row })
            for updatedIndex in updateIndexes {
                if let viewItem = viewItemDelegate?.createViewItem(for: newItems[updatedIndex]) {
                    newViewItems[updatedIndex] = viewItem
                }
            }

            let viewChanges = diff(old: state.viewItems ?? [], new: newViewItems)
            state.items = newItems
            state.viewItems = newViewItems
            DispatchQueue.main.async { [weak self] in
                self?.viewItemDelegate?.reload(with: viewChanges, items: newViewItems, animated: animated)
            }
        }
    }

    func reloadAll() {
        queue.sync {
            var newViewItems = [TransactionViewItem]()
            for item in state.items {
                if let viewItem = viewItemDelegate?.createViewItem(for: item) {
                    newViewItems.append(viewItem)
                }
            }
            let viewChanges = diff(old: state.viewItems ?? [], new: newViewItems)
            state.viewItems = newViewItems
            DispatchQueue.main.async { [weak self] in
                self?.viewItemDelegate?.reload(with: viewChanges, items: newViewItems, animated: false)
            }
        }
    }

    func reload(indexes: [Int]) {
        var updatedViewItems = state.viewItems ?? []
        let oldViewItems = state.viewItems ?? []

        queue.sync {
            for (index, item) in state.items.enumerated() {
                if indexes.contains(index), let viewItem = viewItemDelegate?.createViewItem(for: item) {
                    updatedViewItems[index] = viewItem
                }
            }

            let changes = diff(old: oldViewItems, new: updatedViewItems)
            state.viewItems = updatedViewItems
            DispatchQueue.main.async { [weak self] in
                self?.viewItemDelegate?.reload(with: changes, items: updatedViewItems, animated: true)
            }
        }
    }

    func add(items: [TransactionItem]) {
        var oldItems = state.items
        oldItems.append(contentsOf: items)
        reload(with: oldItems, animated: false)
    }

}
