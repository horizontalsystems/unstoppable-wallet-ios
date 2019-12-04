import ActionSheet

class TransactionOpenFullInfoItem: BaseButtonItem {
    override var createButton: UIButton { .appTertiary }
    override var title: String { "tx_info.button_verify".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: TransactionOpenFullInfoItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = 52
        showSeparator = false
    }

}
