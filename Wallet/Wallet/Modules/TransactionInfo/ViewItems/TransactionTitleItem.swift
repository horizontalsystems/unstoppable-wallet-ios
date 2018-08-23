import Foundation
import GrouviActionSheet

class TransactionTitleItem: BaseActionItem {

    let transactionId: String

    let onIdTap: (() -> ())?


    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false, onIdTap: (() -> ())? = nil) {
        transactionId = transaction.transactionHash
        self.onIdTap = onIdTap

        super.init(cellType: TransactionTitleItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.titleHeight
    }

}
