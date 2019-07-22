import UIKit

class AmountItem: SendItem {
    var showKeyboard: (() -> ())?

    weak var delegate: ISendAmountDelegate?

    var decimal: Int = 2

    var amountInfo: AmountInfo?
    var switchButtonEnabled: Bool = false
    var hintInfo: HintInfo?

    var bindAmount: (() -> ())?
    var bindSwitchButtonEnabled: (() -> ())?
    var bindHint: (() -> ())?
}
