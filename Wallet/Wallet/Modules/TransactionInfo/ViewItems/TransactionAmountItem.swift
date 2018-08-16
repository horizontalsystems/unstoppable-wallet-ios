import Foundation
import GrouviActionSheet

class TransactionAmountItem: BaseActionItem {

    var amount: String
    var amountColor: UIColor
    var date: String

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        amount = "\(transaction.incoming ? "+" : "-") \(CoinValueHelper.formattedAmount(for: transaction.amount))"
        amountColor = transaction.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        date = transaction.status == .success ? DateHelper.instance.formatTransactionInfoTime(from: transaction.date) : "tx_info.bottom_sheet.processing".localized

        super.init(cellType: TransactionAmountItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.amountHeight
    }

}
