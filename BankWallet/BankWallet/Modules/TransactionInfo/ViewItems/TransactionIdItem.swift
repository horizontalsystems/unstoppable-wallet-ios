import ActionSheet

class TransactionIdItem: BaseActionItem {
    let value: String
    var onHashTap: (() -> ())?
    var onShareTap: (() -> ())?

    init(value: String, tag: Int, onHashTap: (() -> ())? = nil, onShareTap: (() -> ())? = nil) {
        self.value = value
        self.onHashTap = onHashTap
        self.onShareTap = onShareTap

        super.init(cellType: TransactionIdItemView.self, tag: tag, required: true)

        height = .heightSingleLineCell
    }

}
