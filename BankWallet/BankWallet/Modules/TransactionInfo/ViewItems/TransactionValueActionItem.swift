import ActionSheet

class TransactionValueActionItem: BaseActionItem {
    let title: String
    let value: String

    var iconName: String?
    var onTap: (() -> ())?

    init(title: String, value: String, tag: Int? = nil, iconName: String? = nil, onTap: (() -> ())? = nil) {
        self.title = title
        self.value = value
        self.iconName = iconName
        self.onTap = onTap

        super.init(cellType: TransactionValueActionItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.itemHeight
    }

}
