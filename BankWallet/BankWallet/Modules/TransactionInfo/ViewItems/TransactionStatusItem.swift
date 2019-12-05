import ActionSheet

class TransactionStatusItem: BaseActionItem {
    var progress: Double?
    var failed: Bool = false
    let type: TransactionType

    init(item: TransactionViewItem, tag: Int? = nil) {
        type = item.type

        super.init(cellType: TransactionStatusItemView.self, tag: tag, required: true)

        switch item.status {
        case .failed:
            failed = true
        case .pending:
            progress = 0
        case .processing(let progress):
            self.progress = progress
        case .completed: ()
        }

        height = .heightSingleLineCell
    }

}
