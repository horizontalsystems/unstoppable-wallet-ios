import Foundation
import GrouviActionSheet

class TransactionTitleItem: BaseActionItem {

    let date: Date?
    let transactionId: String

    let onIdTap: (() -> ())?


    init(item: TransactionViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false, onIdTap: (() -> ())? = nil) {
        date = item.date
        transactionId = item.transactionHash
        self.onIdTap = onIdTap

        super.init(cellType: TransactionTitleItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.titleHeight
    }

}
