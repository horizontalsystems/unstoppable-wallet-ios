import Foundation
import GrouviActionSheet

class TransactionAmountItem: BaseActionItem {

    var amount: String?
    var amountColor: UIColor
    var fiatAmount: String

    init(item: TransactionViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        amount = ValueFormatter.instance.format(coinValue: item.coinValue, explicitSign: true)
        amountColor = item.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor

        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, approximate: true) {
            self.fiatAmount = formattedValue
        } else {
            self.fiatAmount = "n/a"
        }

        super.init(cellType: TransactionAmountItemView.self, tag: tag, hidden: hidden, required: required)

        height = TransactionInfoTheme.amountHeight
    }

}
