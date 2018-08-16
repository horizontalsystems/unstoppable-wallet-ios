import Foundation
import GrouviActionSheet

class TransactionTitleItem: BaseActionItem {

    var title: String
    var amount: String
    var amountColor: UIColor
    var date: String

    let coinIcon: UIImage?
    let onInfo: (() -> ())?

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false, onInfo: (() -> ())? = nil) {
        let statusString = transaction.incoming ? "tx_info.bottom_sheet.title_received".localized : "tx_info.bottom_sheet.title_sent".localized
        title = statusString + " " + transaction.amount.coin.code
        amount = "\(transaction.incoming ? "+" : "-") \(CoinValueHelper.formattedAmount(for: transaction.amount))"
        amountColor = transaction.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        date = transaction.status == .success ? DateHelper.instance.formatTransactionInfoTime(from: transaction.date) : "tx_info.bottom_sheet.processing".localized

        coinIcon = UIImage(named: "Bitcoin Icon")
        self.onInfo = onInfo

        super.init(cellType: TransactionTitleItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.titleHeight
    }

}
