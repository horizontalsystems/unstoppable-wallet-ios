import UIKit

protocol ISendFeePriorityView: class {
    func setPriority()
    func set(enabled: Bool)
    func set(duration: TimeInterval?)
}

protocol ISendFeePriorityViewDelegate {
    var feeRatePriority: FeeRatePriority { get }
    func onFeePrioritySelectorTap()
}

protocol ISendFeePriorityInteractor {
    func syncFeeRate(priority: FeeRatePriority)
}

protocol ISendFeePriorityInteractorDelegate {
    func didUpdate(feeRate: FeeRate)
    func didReceiveError(error: Error)
}

protocol ISendFeePriorityRouter {
    func openPriorities(items: [PriorityItem], onSelect: @escaping (PriorityItem) -> ())
}

protocol ISendFeePriorityDelegate: class {
    func onUpdateFeePriority()
}

protocol ISendFeePriorityModule: AnyObject {
    var delegate: ISendFeePriorityDelegate? { get set }
    var feeRateState: FeeState { get }

    var feeRate: Int? { get }
    var duration: TimeInterval? { get }

    func fetchFeeRate()
}

struct PriorityItem {
    let priority: FeeRatePriority
    let duration: TimeInterval
    let selected: Bool
}
