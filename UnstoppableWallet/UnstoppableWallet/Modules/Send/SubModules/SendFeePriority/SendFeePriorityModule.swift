import UIKit
import CurrencyKit

protocol ISendFeePriorityView: AnyObject {
    func setPriority()
    func set(customVisible: Bool)
    func set(riskOfStuckVisible: Bool)
    func set(customFeeRateValue: Int, customFeeRateRange: ClosedRange<Int>)
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
    var baseCurrency: Currency { get }
}

protocol ISendFeePriorityInteractorDelegate {
    func didUpdate(feeRate: Int)
    func didReceiveError(error: Error)
}

protocol ISendFeePriorityRouter {
    func openPriorities(items: [PriorityItem], onSelect: @escaping (PriorityItem) -> ())
    func openFeeInfo()
}

protocol ISendFeePriorityDelegate: AnyObject {
    func onUpdateFeePriority()
}

protocol ISendFeePriorityModule: AnyObject {
    var delegate: ISendFeePriorityDelegate? { get set }
    var feeRateState: FeeRateState { get }
    var feeRate: Int? { get }

    func fetchFeeRate()
    func set(amountInfo: SendAmountInfo)
    func set(xRate: Decimal?)
    func set(balance: Decimal)
}

struct PriorityItem {
    let priority: FeeRatePriority
    let selected: Bool
}
