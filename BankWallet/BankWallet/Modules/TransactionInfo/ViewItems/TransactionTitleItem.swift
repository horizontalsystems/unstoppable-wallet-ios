import ActionSheet

class TransactionTitleItem: BaseActionItem {
    let transactionHash: String
    let coin: Coin

    let onIdTap: (() -> ())?

    init(item: TransactionViewItem, tag: Int? = nil, onIdTap: (() -> ())? = nil) {
        transactionHash = item.transactionHash
        coin = item.wallet.coin
        self.onIdTap = onIdTap

        super.init(cellType: TransactionTitleItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.titleHeight
    }

}
