import UIKit

protocol ISendFeePriorityView: class {
    func set(priority: FeeRatePriority)
}

protocol ISendFeePriorityViewDelegate {
    func onFeePrioritySelectorTap()
}

protocol ISendFeePriorityInteractor {
    func feeRate(priority: FeeRatePriority) -> Int
}

protocol ISendFeePriorityDelegate: class {
    func onUpdate(feeRate: Int)
}

protocol ISendFeePriorityModule: AnyObject {
    var delegate: ISendFeePriorityDelegate? { get set }
    var feeRate: Int { get }
}
