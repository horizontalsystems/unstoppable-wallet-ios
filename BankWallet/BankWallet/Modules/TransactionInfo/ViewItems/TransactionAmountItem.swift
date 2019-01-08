import Foundation
import GrouviActionSheet

class TransactionAmountItem: BaseActionItem {

    var currencyAmount: String?
    var currencyAmountColor: UIColor
    var amount: String?

    init(item: TransactionViewItem, tag: Int? = nil) {
        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value) {
            currencyAmount = formattedValue
        }
        currencyAmountColor = item.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        amount = ValueFormatter.instance.format(coinValue: item.coinValue)

        super.init(cellType: TransactionAmountItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.amountHeight
    }

}
