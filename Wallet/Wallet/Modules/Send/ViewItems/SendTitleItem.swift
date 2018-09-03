import Foundation
import GrouviActionSheet

class SendTitleItem: BaseActionItem {

    var onQRScan: (() -> ())?
    var title: String?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onQRScan: (() -> ())? = nil) {
        self.onQRScan = onQRScan
        super.init(cellType: SendTitleItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.titleHeight
    }

}
