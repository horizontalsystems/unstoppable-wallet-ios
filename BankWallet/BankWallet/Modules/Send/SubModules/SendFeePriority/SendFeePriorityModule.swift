import UIKit

protocol ISendFeePriorityView: class {
    func setPriority()
}

protocol ISendFeePriorityViewDelegate {
    var feeRatePriority: FeeRatePriority { get }
    func onFeePrioritySelectorTap()
}

protocol ISendFeePriorityInteractor {
    func feeRate(priority: FeeRatePriority) -> Int
    func duration(priority: FeeRatePriority) -> TimeInterval
}

protocol ISendFeePriorityRouter {
    func openPriorities(selected: FeeRatePriority, coin: Coin, priorityDelegate: IPriorityDelegate)
}

protocol ISendFeePriorityDelegate: class {
    func onUpdateFeePriority()
}

protocol ISendFeePriorityModule: AnyObject {
    var delegate: ISendFeePriorityDelegate? { get set }
    var feeRate: Int { get }
    var duration: TimeInterval { get }
}
