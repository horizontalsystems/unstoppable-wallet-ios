import Foundation

class ContainerState<T, S> where T: Hashable, T: Comparable {
    private var state: [T: S]

    init(state: [T: S] = [T: S]()) {
        self.state = state
    }

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

extension ContainerState where S == Bool {

    convenience init() {
        self.init(state: [T: S]())
    }

    var isActive: S {
        state.contains { $1 }
    }

}
