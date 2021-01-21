import UIKit

protocol ISendFeePriorityView: class {
    func setPriority()
    func set(customVisible: Bool)
    func set(customFeeRateValue: Int, customFeeRateRange: ClosedRange<Int>)
    func set(enabled: Bool)
}

protocol ISendFeePriorityViewDelegate {
    var feeRatePriority: FeeRatePriority { get }
    func onFeePrioritySelectorTap()
    func selectCustom(feeRatePriority: FeeRatePriority)
    func onOpenFeeInfo()
}

protocol ISendFeePriorityInteractor {
    func syncFeeRate(priority: FeeRatePriority)
    var defaultFeeRatePriority: FeeRatePriority { get }
    var feeRatePriorityList: [FeeRatePriority] { get }
}

protocol ISendFeePriorityInteractorDelegate {
    func didUpdate(feeRate: Int)
    func didReceiveError(error: Error)
}

protocol ISendFeePriorityRouter {
    func openPriorities(items: [PriorityItem], onSelect: @escaping (PriorityItem) -> ())
    func openFeeInfo()
}

protocol ISendFeePriorityDelegate: class {
    func onUpdateFeePriority()
}

protocol ISendFeePriorityModule: AnyObject {
    var delegate: ISendFeePriorityDelegate? { get set }
    var feeRateState: FeeState { get }
    var feeRate: Int? { get }

    func fetchFeeRate()
    func set(currencyAmount: Decimal?)
}

struct PriorityItem {
    let priority: FeeRatePriority
    let selected: Bool
}
