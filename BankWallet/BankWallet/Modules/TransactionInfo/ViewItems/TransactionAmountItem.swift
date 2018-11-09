import Foundation
import GrouviActionSheet

class TransactionAmountItem: BaseActionItem {

    var amount: String?
    var amountColor: UIColor
    var fiatAmount: String

    init(transaction: TransactionViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        amount = ValueFormatter.instance.format(coinValue: transaction.coinValue, explicitSign: true)
        amountColor = transaction.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
//        let currencyValue = CurrencyValue(currency: DollarCurrency(), value: abs(transaction.amount.value) * 6000)
//        fiatAmount = "~ \(CurrencyHelper.instance.formattedValue(for: currencyValue) ?? "0")"
        if let value = transaction.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, approximate: true) {
            self.fiatAmount = formattedValue
        } else {
            self.fiatAmount = "n/a"
        }

        super.init(cellType: TransactionAmountItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.amountHeight
    }

}
