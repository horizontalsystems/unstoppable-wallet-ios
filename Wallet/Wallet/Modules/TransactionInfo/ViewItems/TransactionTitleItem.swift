import Foundation
import GrouviActionSheet

class TransactionTitleItem: BaseActionItem {

    var title: String
    var amount: String
    var amountColor: UIColor
    var date: String

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        title = transaction.incoming ? "tx_info.bottom_sheet.title_received".localized : "tx_info.bottom_sheet.title_sent".localized
        amount = "\(transaction.incoming ? "+" : "-") \(CoinValueHelper.formattedAmount(for: transaction.amount))"
        amountColor = transaction.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        date = DateHelper.instance.formatTransactionInfoTime(from: transaction.date)

        super.init(cellType: TransactionTitleItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = TransactionInfoTheme.titleHeight
    }

}
