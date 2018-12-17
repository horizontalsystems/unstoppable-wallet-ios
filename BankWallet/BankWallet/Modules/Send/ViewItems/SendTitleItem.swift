import GrouviActionSheet

class SendTitleItem: BaseActionItem {

    var bindCoin: ((CoinCode) -> ())?

    init(tag: Int) {
        super.init(cellType: SendTitleItemView.self, tag: tag, required: true)

        height = SendTheme.titleHeight
    }

}
