import ActionSheet

class TransactionValueActionItem: BaseActionItem {
    let title: String
    let value: String

    init(title: String, value: String, tag: Int? = nil) {
        self.title = title
        self.value = value

        super.init(cellType: TransactionValueActionItemView.self, tag: tag, required: true)

        height = .heightSingleLineCell
    }

}
