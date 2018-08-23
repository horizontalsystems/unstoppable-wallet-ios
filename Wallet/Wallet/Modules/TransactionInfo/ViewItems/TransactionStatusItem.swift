import Foundation
import GrouviActionSheet

class TransactionStatusItem: TransactionInfoBaseValueItem {

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(tag: tag, hidden: hidden, required: required)

        title = "tx_info.bottom_sheet.status".localized
        value = transaction.status == .success ? "tx_info.bottom_sheet.complete".localized : "tx_info.bottom_sheet.pending".localized
        valueImage = transaction.status == .success ? UIImage(named: "Transaction Success Icon") : UIImage(named: "Transaction Processing Icon")
        valueColor = transaction.status == .success ? TransactionInfoTheme.statusCompleteValueColor : TransactionInfoTheme.statusPendingValueColor
    }

}
