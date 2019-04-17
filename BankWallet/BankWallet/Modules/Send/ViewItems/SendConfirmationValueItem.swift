import ActionSheet

class SendConfirmationValueItem: BaseActionItem {
    let title: String
    let value: String?

    init(title: String, amountInfo: AmountInfo, isFee: Bool = true, tag: Int) {
        self.title = title

        switch amountInfo {
        case .coinValue(let coinValue):
            value = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            value = ValueFormatter.instance.format(currencyValue: currencyValue, roundingMode: .up)
        }

        super.init(cellType: SendConfirmationValueItemView.self, tag: tag, required: true)

        showSeparator = false
        if isFee {
            height = SendTheme.confirmationFeeValueHeight
        } else {
            height = SendTheme.confirmationTotalValueHeight
        }
    }

}
