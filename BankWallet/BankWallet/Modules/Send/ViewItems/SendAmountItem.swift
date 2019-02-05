import GrouviActionSheet

class SendAmountItem: BaseActionItem {
    var onSwitchClicked: (() -> ())?
    var onAmountChanged: ((Decimal) -> ())?
    var onMaxClicked: (() -> ())?

    var bindAmountType: ((String?) -> ())?
    var bindAmount: ((Decimal?) -> ())?
    var bindHint: ((String?) -> ())?
    var bindError: ((String?) -> ())?
    var bindSwitchEnabled: ((Bool) -> ())?

    var addLetter: ((String) -> ())?
    var removeLetter: (() -> ())?

    var showKeyboard: (() -> ())?

    var decimal: Int = 2

    var onPasteClicked: (() -> ())?

    init(tag: Int) {
        super.init(cellType: SendAmountItemView.self, tag: tag, required: true)

        height = SendTheme.amountHeight
    }

}
