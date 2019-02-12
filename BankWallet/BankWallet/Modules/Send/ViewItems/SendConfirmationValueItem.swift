import GrouviActionSheet

class SendConfirmationValueItem: BaseActionItem {
    let title: String
    let value: String?

    init(title: String, amountInfo: AmountInfo, tag: Int) {
        self.title = title

        switch amountInfo {
        case .coinValue(let coinValue):
            value = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            value = ValueFormatter.instance.format(currencyValue: currencyValue, roundingMode: .up)
        }

        super.init(cellType: SendConfirmationValueItemView.self, tag: tag, required: true)

        showSeparator = false
        height = SendTheme.confirmationValueHeight
    }

}
