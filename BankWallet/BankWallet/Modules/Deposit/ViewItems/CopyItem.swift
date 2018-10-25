import Foundation
import GrouviActionSheet

class CopyItem: BaseActionItem {

    var onCopy: (() -> ())?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onCopy: (() -> ())? = nil) {
        self.onCopy = onCopy
        super.init(cellType: CopyItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = DepositTheme.copyHeight
    }

}
