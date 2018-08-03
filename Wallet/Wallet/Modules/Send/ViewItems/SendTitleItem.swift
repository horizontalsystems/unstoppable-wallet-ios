import Foundation
import GrouviActionSheet

class SendTitleItem: BaseActionItem {

    var onQRScan: (() -> ())?
    var coinCode: String

    init(coinCode: String, tag: Int? = nil, hidden: Bool = false, required: Bool = false, onQRScan: (() -> ())? = nil) {
        self.coinCode = coinCode
        self.onQRScan = onQRScan
        super.init(cellType: SendTitleItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.titleHeight
    }

}
