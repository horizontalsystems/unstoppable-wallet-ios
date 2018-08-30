import Foundation
import GrouviActionSheet

class TransactionStatusItem: BaseActionItem {

    var title: String?
    var value: String?
    var valueColor: UIColor?
    var valueImage: UIImage?
    var valueImageTintColor: UIColor?


    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(cellType: TransactionStatusItemView.self, tag: tag, hidden: hidden, required: required)

        title = "tx_info.bottom_sheet.status".localized
        value = transaction.status == .success ? "tx_info.bottom_sheet.complete".localized : "tx_info.bottom_sheet.pending".localized
        valueColor = transaction.status == .success ? TransactionInfoTheme.statusCompleteValueColor : TransactionInfoTheme.statusPendingValueColor
        valueImage = transaction.status == .success ? UIImage(named: "Transaction Success Icon") : UIImage(named: "Transaction Processing Icon")
        valueImageTintColor = transaction.status == .success ? TransactionInfoTheme.successIconTintColor : TransactionInfoTheme.processingIconTintColor
    }

}
