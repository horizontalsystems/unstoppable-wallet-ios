import Foundation
import GrouviActionSheet

class TransactionAmountItem: BaseActionItem {

    var date: String
    var amount: String
    var amountColor: UIColor
    var fiatAmount: String

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        date = transaction.date.map { DateHelper.instance.formatTransactionInfoTime(from: $0) } ?? ""
        amount = "\(transaction.incoming ? "+" : "-") \(CoinValueHelper.formattedAmount(for: transaction.amount))"
        amountColor = transaction.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
//        let currencyValue = CurrencyValue(currency: DollarCurrency(), value: abs(transaction.amount.value) * 6000)
//        fiatAmount = "~ \(CurrencyHelper.instance.formattedValue(for: currencyValue) ?? "0")"
        fiatAmount = "~ n/a"

        super.init(cellType: TransactionAmountItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.amountHeight
    }

}
