import Foundation
import GrouviActionSheet

class SendAmountItem: BaseActionItem {

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(cellType: SendTitleItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.twinHeight
    }

}
