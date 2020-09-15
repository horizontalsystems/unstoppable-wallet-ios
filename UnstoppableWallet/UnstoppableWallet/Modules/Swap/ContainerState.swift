import Foundation

class ContainerState<T, S> where T: Hashable, T: Comparable {
    private var state = [T: S]()

    func get(by type: T) -> S? {
        state[type]
    }

    func set(to type: T, value: S?) {
        state[type] = value
    }

    var first: S? {
        state.sorted { $0.key > $1.key }.first?.value
    }

}
