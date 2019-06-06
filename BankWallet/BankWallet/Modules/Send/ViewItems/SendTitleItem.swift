import ActionSheet

class ActionTitleItem: BaseActionItem {

    var bindTitle: ((_ title: String, _ coin: Coin) -> ())?

    init(tag: Int) {
        super.init(cellType: ActionTitleItemView.self, tag: tag, required: true)

        height = SendTheme.titleHeight
    }

}
