class CurrencyValueFormatter {
    private let amountRoundingManager: AmountRoundingManager

    init(amountRoundingManager: AmountRoundingManager) {
        self.amountRoundingManager = amountRoundingManager
    }
}

extension CurrencyValueFormatter {
    func formatCurrency(_ currencyValue: CurrencyValue) -> String? {
        if amountRoundingManager.useAmountRounding {
            return ValueFormatter.instance.formatShort(currencyValue: currencyValue)
        }
        return ValueFormatter.instance.formatFull(currencyValue: currencyValue)
    }
}
