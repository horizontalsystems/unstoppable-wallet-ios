import Foundation
import ActionSheet

class TransactionAmountItem: BaseActionItem {

    var currencyAmount: String?
    var currencyAmountColor: UIColor
    var amount: String?
    var coinName: String?

    init(item: TransactionViewItem, tag: Int? = nil) {
        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01), trimmable: false) {
            currencyAmount = formattedValue

            if item.sentToSelf {
                currencyAmount = "\(formattedValue)*"
            }
        }
        currencyAmountColor = item.incoming ? TransactionInfoTheme.incomingAmountColor : TransactionInfoTheme.outgoingAmountColor
        amount = ValueFormatter.instance.format(coinValue: item.coinValue)
        coinName = item.wallet.coin.title.localized

        super.init(cellType: TransactionAmountItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.amountHeight
    }

}
