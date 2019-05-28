import DeepDiff

class TransactionsDiffer {
    let queue = DispatchQueue.global(qos: .userInteractive)

    weak var viewItemDelegate: ITransactionViewItemDataSourceDelegate?
    var async: Bool

    private var items = [TransactionItem]()
    private var viewItems: [TransactionViewItem]?

    init(async: Bool = true) {
        self.async = async
    }

    private func buildViewItems(from items: [TransactionItem]) -> [TransactionViewItem] {
        var viewItems = [TransactionViewItem]()
        for item in items {
            if let viewItem = viewItemDelegate?.viewItem(for: item) {
                viewItems.append(viewItem)
            }
        }
        return viewItems
    }

}

extension TransactionsDiffer: ITransactionViewItemDataSource {

    var viewItemsCount: Int {
        return viewItems?.count ?? 0
    }

    func viewItem(at index: Int) -> TransactionViewItem? {
        return viewItems?[index]
    }

    func reload(with newItems: [TransactionItem], animated: Bool) {
        queue.sync {
            let needFullReload = !animated || viewItems == nil

            var newViewItems = viewItems ?? []
            let itemsChanges = IndexPathConverter().convert(changes: diff(old: items, new: newItems), section: 0)
            for index in itemsChanges.deletes.sorted().reversed() {
                newViewItems.remove(at: index.row)
            }
            for index in itemsChanges.inserts {
                if let viewItem = viewItemDelegate?.viewItem(for: newItems[index.row]) {
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
                if let viewItem = viewItemDelegate?.viewItem(for: newItems[updatedIndex]) {
                    newViewItems[updatedIndex] = viewItem
                }
            }

            let viewChanges = diff(old: viewItems ?? [], new: newViewItems)
            items = newItems
            viewItems = newViewItems
            DispatchQueue.main.async { [weak self] in
                if needFullReload {
                    self?.viewItemDelegate?.reload()
                } else {
                    self?.viewItemDelegate?.reload(with: viewChanges)
                }
            }
        }
    }

    func reloadAll() {
        reload(with: items, animated: false)
    }

    func reload(indexes: [Int]) {
        var updatedViewItems = viewItems ?? []
        let oldViewItems = viewItems ?? []

        queue.sync {
            for (index, item) in items.enumerated() {
                if indexes.contains(index), let viewItem = viewItemDelegate?.viewItem(for: item) {
                    updatedViewItems[index] = viewItem
                }
            }

            let changes = diff(old: oldViewItems, new: updatedViewItems)
            viewItems = updatedViewItems
            DispatchQueue.main.async { [weak self] in
                self?.viewItemDelegate?.reload(with: changes)
            }
        }
    }

    func add(items: [TransactionItem]) {
        viewItems = viewItems == nil ? [] : viewItems

        queue.sync {
            let newViewItems = buildViewItems(from: items)

            self.items.append(contentsOf: items)
            viewItems?.append(contentsOf: newViewItems)
            DispatchQueue.main.async { [weak self] in
                self?.viewItemDelegate?.reload()
            }
        }
    }

}
