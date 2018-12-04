import GrouviActionSheet

class SendAmountItem: BaseActionItem {
    var onSwitchClicked: (() -> ())?
    var onAmountChanged: ((Double) -> ())?

    var bindAmountType: ((String?) -> ())?
    var bindAmount: ((Double?, Bool) -> ())?
    var bindHint: ((String?) -> ())?
    var bindError: ((String?) -> ())?
    var bindSwitchEnabled: ((Bool) -> ())?

    var showKeyboard: (() -> ())?

    init(tag: Int) {
        super.init(cellType: SendAmountItemView.self, tag: tag, required: true)

        height = SendTheme.amountHeight
    }

}
