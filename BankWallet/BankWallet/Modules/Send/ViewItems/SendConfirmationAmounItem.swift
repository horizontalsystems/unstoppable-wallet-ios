import ActionSheet

class SendConfirmationAmounItem: BaseActionItem {
    let primaryAmount: String?
    var secondaryAmount: String?

    init(viewItem: SendConfirmationViewItem, tag: Int) {
        switch viewItem.primaryAmountInfo {
        case .coinValue(let coinValue):
            primaryAmount = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            primaryAmount = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(threshold: 100))
        }

        if let secondaryAmountInfo = viewItem.secondaryAmountInfo {
            switch secondaryAmountInfo {
            case .coinValue(let coinValue):
                secondaryAmount = ValueFormatter.instance.format(coinValue: coinValue)
            case .currencyValue(let currencyValue):
                secondaryAmount = ValueFormatter.instance.format(currencyValue: currencyValue)
            }
        }

        super.init(cellType: SendConfirmationAmountItemView.self, tag: tag, required: true)

        showSeparator = true
        height = SendTheme.confirmationAmountHeight
    }

}
