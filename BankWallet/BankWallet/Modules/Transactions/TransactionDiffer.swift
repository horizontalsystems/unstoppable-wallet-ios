import DeepDiff

class TransactionDiffer: IDiffer {

    func changes<T: DiffAware>(old: [T], new: [T], section: Int) -> ChangeWithIndexPath {
        var inserts = [IndexPath]()
        var deletes = [IndexPath]()
        var replaces = [IndexPath]()

        for (index, oldItem) in old.enumerated() {
            if new.count <= index {
                deletes.append(IndexPath(item: index, section: section))
                continue
            }

            let newItem = new[index]

            if oldItem.diffId == newItem.diffId && T.compareContent(oldItem, newItem) {
                continue
            }

            replaces.append(IndexPath(item: index, section: section))
        }

        if new.count > old.count {
            for i in old.count..<new.count {
                inserts.append(IndexPath(item: i, section: section))
            }
        }

        return ChangeWithIndexPath(
                inserts: inserts,
                deletes: deletes,
                replaces: replaces,
                moves: []
        )
    }

}
