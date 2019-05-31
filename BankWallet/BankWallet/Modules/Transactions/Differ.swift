import DeepDiff

class Differ: IDiffer {

    func changes<T: DiffAware>(old: [T], new: [T]) -> [Change<T>] {
        return diff(old: old, new: new)
    }

}
