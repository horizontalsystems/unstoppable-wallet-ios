import GrouviActionSheet

class TransactionTitleItem: BaseActionItem {
    let transactionId: String

    let onIdTap: (() -> ())?

    init(item: TransactionViewItem, tag: Int? = nil, onIdTap: (() -> ())? = nil) {
        transactionId = item.transactionHash
        self.onIdTap = onIdTap

        super.init(cellType: TransactionTitleItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.titleHeight
    }

}
