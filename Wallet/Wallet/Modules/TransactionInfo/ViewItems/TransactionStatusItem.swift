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

        valueColor = TransactionInfoTheme.statusPendingValueColor
        valueImageTintColor = TransactionInfoTheme.processingIconTintColor
        valueImage = UIImage(named: "Transaction Processing Icon")
        switch transaction.status {
        case .processing:
            value = "tx_info.bottom_sheet.processing".localized
        case let .verifying(progress):
            value = "verifying \(Int(progress * 100))%"
        case .completed:
            value = "tx_info.bottom_sheet.complete".localized
            valueColor = TransactionInfoTheme.statusCompleteValueColor
            valueImage = UIImage(named: "Transaction Success Icon")
            valueImageTintColor = TransactionInfoTheme.successIconTintColor
        }
    }

}
