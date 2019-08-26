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
}

protocol ISendFeePriorityRouter {
    func openPriorities(selected: FeeRatePriority, priorityDelegate: IPriorityDelegate)
}

protocol ISendFeePriorityDelegate: class {
    func onUpdate(feeRate: Int)
}

protocol ISendFeePriorityModule: AnyObject {
    var delegate: ISendFeePriorityDelegate? { get set }
    var feeRate: Int { get }
}
