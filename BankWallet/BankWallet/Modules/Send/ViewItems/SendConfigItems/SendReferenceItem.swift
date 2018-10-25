import Foundation
import GrouviActionSheet

class SendReferenceItem: BaseActionItem {

    let deliverTimeFrame: String = "Time: ~ 24 hours"
    let feeString: String = "fee: $0,00"

    var onBack: (() -> ())?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onBack: (() -> ())? = nil) {
        self.onBack = onBack

        super.init(cellType: SendReferenceItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = SendTheme.twinHeight
    }

}
