import UIKit

protocol ISendFeeSliderView: class {
}

protocol ISendFeeSliderViewDelegate {
    func onFeePriorityChange(value: Int)
}

protocol ISendFeeSliderInteractor {
    func feeRate(priority: FeeRatePriority) -> Int
}

protocol ISendFeeSliderDelegate: class {
    func onUpdate(feeRate: Int)
}

protocol ISendFeeSliderModule: AnyObject {
    var delegate: ISendFeeSliderDelegate? { get set }
    var feeRate: Int { get }
}
