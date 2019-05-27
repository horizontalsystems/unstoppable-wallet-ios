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
            let newViewItems = buildViewItems(from: newItems)
            let changes = diff(old: viewItems ?? [], new: newViewItems)

            let needFullReload = !animated || viewItems == nil
            items = newItems
            viewItems = newViewItems
            DispatchQueue.main.async { [weak self] in
                if needFullReload {
                    self?.viewItemDelegate?.reload()
                } else {
                    self?.viewItemDelegate?.reload(with: changes)
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
