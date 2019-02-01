import GrouviActionSheet

class TransactionStatusItem: BaseActionItem {
    let title: String
    var statusText: String?
    var icon: UIImage?
    var progress: Double?

    init(item: TransactionViewItem, tag: Int? = nil) {
        title = "tx_info.status".localized

        super.init(cellType: TransactionStatusItemView.self, tag: tag, required: true)

        switch item.status {
        case .pending:
            icon = UIImage(named: "Transaction Info Pending Icon")
            statusText = "tx_info.status.pending".localized
        case .processing(let progress):
            self.progress = progress
        case .completed:
            icon = UIImage(named: "Transaction Info Completed Icon")
        }

        height = TransactionInfoTheme.itemHeight
    }

}
