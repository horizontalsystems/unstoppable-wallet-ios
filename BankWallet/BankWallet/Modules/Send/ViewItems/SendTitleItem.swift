import ActionSheet

class SendTitleItem: BaseActionItem {

    var bindCoin: ((Coin) -> ())?

    init(tag: Int) {
        super.init(cellType: SendTitleItemView.self, tag: tag, required: true)

        height = SendTheme.titleHeight
    }

}
