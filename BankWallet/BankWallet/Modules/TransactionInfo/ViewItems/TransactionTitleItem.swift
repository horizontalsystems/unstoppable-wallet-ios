import ActionSheet

class TransactionTitleItem: BaseActionItem {
    let coin: Coin
    let onClose: (() -> ())?

    init(coin: Coin, tag: Int? = nil, onClose: (() -> ())? = nil) {
        self.coin = coin
        self.onClose = onClose

        super.init(cellType: TransactionTitleItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.titleHeight
    }

}
