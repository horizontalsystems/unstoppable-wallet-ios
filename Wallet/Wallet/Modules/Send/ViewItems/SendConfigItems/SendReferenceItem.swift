import Foundation
import GrouviActionSheet

class SendReferenceItem: BaseActionItem {

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(cellType: SendReferenceItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.twinHeight
    }

}
