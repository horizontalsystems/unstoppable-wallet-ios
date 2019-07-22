import UIKit

class SFeeItem: SendItem {
    let isFeeAdjustable: Bool

    weak var delegate: ISendFeeDelegate?

    var feeInfo: FeeInfo?

    init(isFeeAdjustable: Bool) {
        self.isFeeAdjustable = isFeeAdjustable
    }

}
