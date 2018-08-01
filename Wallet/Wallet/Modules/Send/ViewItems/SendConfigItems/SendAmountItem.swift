import Foundation
import GrouviActionSheet

class SendAmountItem: BaseActionItem {

    var onMore: (() -> ())?
    var onPaste: (() -> ())?

    var onCurrencyChange: (() -> ())?
    var onAmountEntered: ((String?) -> ())?

    var address: String?
    var currencyCode: String?
    var amount: String?
    var hint: String?

    var error: SendError?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onMore: (() -> ())? = nil) {
        self.onMore = onMore

        super.init(cellType: SendTitleItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.twinHeight
    }

}
