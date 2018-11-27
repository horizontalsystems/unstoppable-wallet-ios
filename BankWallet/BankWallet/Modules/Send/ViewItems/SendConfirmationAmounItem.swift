import GrouviActionSheet

class SendConfirmationAmounItem: BaseActionItem {
    let amount: String?
    var fiatAmount: String?

    init(viewItem: SendConfirmationViewItem, tag: Int) {
        amount = ValueFormatter.instance.format(coinValue: viewItem.coinValue)

        if let value = viewItem.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value) {
            fiatAmount = formattedValue
        }

        super.init(cellType: SendConfirmationAmountItemView.self, tag: tag, required: true)

        showSeparator = false
        height = SendTheme.confirmationAmountHeight
    }

}
