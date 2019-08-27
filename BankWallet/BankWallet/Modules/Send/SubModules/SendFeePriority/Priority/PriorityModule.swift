import Foundation

protocol IPriorityInteractor {
    func duration(priority: FeeRatePriority) -> TimeInterval
}

protocol IPriorityRouter {
    func dismiss(with sort: FeeRatePriority)
}

protocol IPriorityDelegate: class {
    func onSelect(priority: FeeRatePriority)
}
