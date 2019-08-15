class SendConfirmationItemFactory: ISendConfirmationItemFactory {

    func viewItem(sendInputType: SendInputType, coinAmountValue: CoinValue, currencyAmountValue: CurrencyValue?, receiver: String, showMemo: Bool, coinFeeValue: CoinValue?, currencyFeeValue: CurrencyValue?, estimateTime: String?) -> SendConfirmationViewItem? {
        guard let coinAmountString: String = ValueFormatter.instance.format(coinValue: coinAmountValue) else {
            return nil
        }
        var fiatAmountString: String? = nil

        if let fiatAmount = currencyAmountValue {
            fiatAmountString = ValueFormatter.instance.format(currencyValue: fiatAmount)
        }

        let primaryAmountInfo: String
        let secondaryAmountInfo: String?
        if sendInputType == .coin {
            primaryAmountInfo = coinAmountString
            secondaryAmountInfo = fiatAmountString
        } else {
            primaryAmountInfo = fiatAmountString ?? coinAmountString
            secondaryAmountInfo = fiatAmountString != nil ? coinAmountString : nil
        }

        var feeString: String?
        if let fiatFee = currencyFeeValue {
            feeString = ValueFormatter.instance.format(currencyValue: fiatFee)
        } else if let coinFeeValue = coinFeeValue {
            feeString = ValueFormatter.instance.format(coinValue: coinFeeValue)
        }

        var totalInfo: String? = nil
        if let fiatAmount = currencyAmountValue, let fiatFee = currencyFeeValue, fiatAmount.currency == fiatFee.currency {
            let totalValue = fiatAmount.value + fiatFee.value
            totalInfo = ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: fiatAmount.currency, value: totalValue))
        }
        return SendConfirmationViewItem(primaryAmount: primaryAmountInfo, secondaryAmount: secondaryAmountInfo, receiver: receiver, showMemo: showMemo, feeInfo: feeString, totalInfo: totalInfo, estimateTime: estimateTime)
    }

}
