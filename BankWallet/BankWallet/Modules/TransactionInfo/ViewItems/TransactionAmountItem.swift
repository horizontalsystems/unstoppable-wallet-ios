import Foundation
import ActionSheet

class TransactionAmountItem: BaseActionItem {

    var currencyAmount: String?
    var currencyAmountColor: UIColor
    var amount: String?
    var coinName: String?

    init(item: TransactionViewItem, tag: Int? = nil) {
        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value) {
            currencyAmount = formattedValue
        }
        currencyAmountColor = item.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        amount = ValueFormatter.instance.format(coinValue: item.coinValue)
        coinName = item.wallet.coin.title.localized

        super.init(cellType: TransactionAmountItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.amountHeight
    }

}
