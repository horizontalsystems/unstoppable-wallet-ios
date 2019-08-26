protocol IPriorityInteractor {
    func set(priority: FeeRatePriority)
}

protocol IPriorityRouter {
    func dismiss(with sort: FeeRatePriority)
}

protocol IPriorityDelegate: class {
    func onSelect(priority: FeeRatePriority)
}
