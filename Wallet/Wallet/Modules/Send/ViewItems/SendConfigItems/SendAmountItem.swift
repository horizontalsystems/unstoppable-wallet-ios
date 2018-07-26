import Foundation
import GrouviActionSheet

class SendAmountItem: BaseActionItem {

    var onMore: (() -> ())?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onMore: (() -> ())? = nil) {
        self.onMore = onMore

        super.init(cellType: SendTitleItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.twinHeight
    }

}
