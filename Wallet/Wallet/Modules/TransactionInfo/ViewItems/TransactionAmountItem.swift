import Foundation
import GrouviActionSheet

class TransactionAmountItem: BaseActionItem {

    var date: String
    var amount: String
    var amountColor: UIColor
    var fiatAmount: String

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        date = transaction.status == .success ? DateHelper.instance.formatTransactionInfoTime(from: transaction.date) : "tx_info.bottom_sheet.processing".localized
        amount = "\(transaction.incoming ? "+" : "-") \(CoinValueHelper.formattedAmount(for: transaction.amount))"
        amountColor = transaction.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        //stab
        let currencyValue = CurrencyValue(currency: DollarCurrency(), value: abs(transaction.amount.value) * 6000)
        fiatAmount = "~ \(CurrencyHelper.instance.formattedValue(for: currencyValue) ?? "0")"

        super.init(cellType: TransactionAmountItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.amountHeight
    }

}
