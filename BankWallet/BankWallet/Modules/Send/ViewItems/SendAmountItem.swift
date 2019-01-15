import GrouviActionSheet

class SendAmountItem: BaseActionItem {
    var onSwitchClicked: (() -> ())?
    var onAmountChanged: ((Double) -> ())?

    var bindAmountType: ((String?) -> ())?
    var bindAmount: ((Double?) -> ())?
    var bindHint: ((String?) -> ())?
    var bindError: ((String?) -> ())?
    var bindSwitchEnabled: ((Bool) -> ())?

    var addLetter: ((String) -> ())?
    var removeLetter: (() -> ())?

    var showKeyboard: (() -> ())?

    init(tag: Int) {
        super.init(cellType: SendAmountItemView.self, tag: tag, required: true)

        height = SendTheme.amountHeight
    }

}
