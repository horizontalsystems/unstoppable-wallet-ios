import Foundation
import GrouviActionSheet

class TransactionStatusItem: BaseActionItem {

    var title: String?
    var value: String?
    var valueImage: UIImage?
    var valueImageTintColor: UIColor?
    var progress: Double?

    init(item: TransactionViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(cellType: TransactionStatusItemView.self, tag: tag, hidden: hidden, required: required)

        title = "tx_info.status".localized

        switch item.status {
        case .pending:
            value = "tx_info.pending".localized
            valueImage = UIImage(named: "Transaction Processing Icon")
            valueImageTintColor = TransactionInfoTheme.processingIconTintColor
        case .processing(let progress):
            value = "tx_info.processing".localized("\(Int(progress * 100))%")
            self.progress = progress
        case .completed:
            value = "tx_info.bottom_sheet.completed".localized
            valueImage = UIImage(named: "Transaction Success Icon")
            valueImageTintColor = TransactionInfoTheme.successIconTintColor
        }
    }

}
