class SendConfirmationViewItemFactory: ISendConfirmationViewItemFactory {

    func confirmationViewItem(coin: Coin, sendInputType: SendInputType, address: String?, coinAmountValue: CoinValue, currencyAmountValue: CurrencyValue?, coinFeeValue: CoinValue, currencyFeeValue: CurrencyValue?) throws -> SendConfirmationViewItem {

        guard let address = address else {
            throw SendPresenter.SendError.noAddress
        }

        let coinAmountInfo = AmountInfo.coinValue(coinValue: coinAmountValue)
        var fiatAmountInfo: AmountInfo? = nil

        if let fiatAmount = currencyAmountValue {
            fiatAmountInfo = AmountInfo.currencyValue(currencyValue: fiatAmount)
        }

        let primaryAmountInfo: AmountInfo
        let secondaryAmountInfo: AmountInfo?
        if sendInputType == .coin {
            primaryAmountInfo = coinAmountInfo
            secondaryAmountInfo = fiatAmountInfo
        } else {
            primaryAmountInfo = fiatAmountInfo ?? coinAmountInfo
            secondaryAmountInfo = fiatAmountInfo != nil ? coinAmountInfo : nil
        }

        let feeInfo: AmountInfo
        if let fiatFee = currencyFeeValue {
            feeInfo = AmountInfo.currencyValue(currencyValue: fiatFee)
        } else {
            feeInfo = AmountInfo.coinValue(coinValue: coinFeeValue)
        }

        var totalInfo: AmountInfo? = nil
        if let fiatAmount = currencyAmountValue, let fiatFee = currencyFeeValue, fiatAmount.currency == fiatFee.currency {
            let totalValue = fiatAmount.value + fiatFee.value
            totalInfo = AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: fiatAmount.currency, value: totalValue))
        }
        return SendConfirmationViewItem(coin: coin, primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo, address: address, feeInfo: feeInfo, totalInfo: totalInfo)
    }

}
