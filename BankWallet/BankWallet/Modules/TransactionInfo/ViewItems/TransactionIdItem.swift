import ActionSheet

class TransactionIdItem: BaseActionItem {
    let value: String
    var onHashTap: (() -> ())?

    init(value: String, tag: Int, onHashTap: (() -> ())? = nil) {
        self.value = value
        self.onHashTap = onHashTap

        super.init(cellType: TransactionIdItemView.self, tag: tag, required: true)

        height = .heightSingleLineCell
    }

}
