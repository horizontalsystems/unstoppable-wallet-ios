import ActionSheet

class TransactionOpenFullInfoItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return [RespondButton.State.active: TransactionInfoTheme.openFullInfoButtonBackground, RespondButton.State.selected: TransactionInfoTheme.openFullInfoButtonBackground] }
    override var textStyle: RespondButton.Style { return [RespondButton.State.active: TransactionInfoTheme.openFullInfoButtonTextColor, RespondButton.State.selected: TransactionInfoTheme.openFullInfoButtonTextColorSelected] }
    override var title: String { return "tx_info.button_verify".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: TransactionOpenFullInfoItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = TransactionInfoTheme.openFullInfoHeight
        showSeparator = false
    }

}
