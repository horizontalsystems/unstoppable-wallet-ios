import Foundation
import GrouviActionSheet

class SendAmountItem: BaseActionItem {

//    var onMore: (() -> ())?
    var onPaste: (() -> ())?

    var onCurrencyChange: (() -> ())?
    var onAmountEntered: ((String?) -> ())?
    var onAddressEntered: ((String?) -> ())?

    var showKeyboardOnLoad: (() -> ())?

    var address: String?
    var currencyCode: String?
    var amount: String?
    var hint: String?
    var hintColor: UIColor?

    var error: SendError?

    var addressValid = true

    var reload: (() -> ())?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onMore: (() -> ())? = nil) {
//        self.onMore = onMore

        super.init(cellType: SendAmountItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.twinHeight
    }

}
