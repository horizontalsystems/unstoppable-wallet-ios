import ActionSheet

class TransactionStatusItem: BaseActionItem {
    var progress: Double?
    let incoming: Bool

    init(item: TransactionViewItem, tag: Int? = nil) {
        incoming = item.incoming

        super.init(cellType: TransactionStatusItemView.self, tag: tag, required: true)

        switch item.status {
        case .pending:
            progress = 0
        case .processing(let progress):
            self.progress = progress
        case .completed: ()
        }

        height = TransactionInfoTheme.itemHeight
    }

}
