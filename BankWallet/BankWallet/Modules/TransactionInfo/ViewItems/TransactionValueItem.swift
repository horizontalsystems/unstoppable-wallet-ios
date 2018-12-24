import GrouviActionSheet

class TransactionValueItem: BaseActionItem {
    let title: String
    let value: String

    init(title: String, value: String, tag: Int? = nil) {
        self.title = title
        self.value = value

        super.init(cellType: TransactionValueItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.itemHeight
    }

}
