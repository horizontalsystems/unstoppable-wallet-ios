import GrouviActionSheet

class TransactionStatusItem: BaseActionItem {
    let title: String
    var statusText: String?
    var statusColor: UIColor?
    var icon: UIImage?
    var progress: Double?

    init(item: TransactionViewItem, tag: Int? = nil) {
        title = "tx_info.status".localized

        super.init(cellType: TransactionStatusItemView.self, tag: tag, required: true)

        switch item.status {
        case .pending:
            icon = UIImage(named: "Transaction Info Pending Icon")?.tinted(with: .cryptoGray)
            statusText = "tx_info.status.pending".localized
            statusColor = TransactionInfoTheme.pendingStatusColor
        case .processing(let progress):
            self.progress = progress
        case .completed:
            icon = UIImage(named: "Transaction Info Completed Icon")?.tinted(with: .cryptoGreen)
            statusText = "tx_info.status.confirmed".localized
            statusColor = TransactionInfoTheme.completeStatusColor
        }

        height = TransactionInfoTheme.itemHeight
    }

}
