class SendStateViewItemFactory: ISendStateViewItemFactory {

    func viewItem(forState state: SendState, forceRoundDown: Bool) -> SendStateViewItem {
        let viewItem = SendStateViewItem(decimal: state.decimal)
        viewItem.feeInfo = FeeInfo()

        switch state.inputType {
        case .coin:
            viewItem.amountInfo = state.coinValue.map {
                let roundedValue = ValueFormatter.instance.round(value: $0.value, scale: state.decimal, roundingMode: .down)
                return AmountInfo.coinValue(coinValue: CoinValue(coinCode: $0.coinCode, value: roundedValue))
            }
            viewItem.feeInfo?.primaryFeeInfo = state.feeCoinValue.map { AmountInfo.coinValue(coinValue: $0) }
            viewItem.feeInfo?.secondaryFeeInfo = state.feeCurrencyValue.map { AmountInfo.currencyValue(currencyValue: $0) }
        case .currency:
            viewItem.amountInfo = state.currencyValue.map {
                let roundedValue = ValueFormatter.instance.round(value: $0.value, scale: state.decimal, roundingMode: forceRoundDown ? .down : .up)
                return AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: $0.currency, value: roundedValue))
            }
            viewItem.feeInfo?.primaryFeeInfo = state.feeCurrencyValue.map { AmountInfo.currencyValue(currencyValue: $0) }
            viewItem.feeInfo?.secondaryFeeInfo = state.feeCoinValue.map { AmountInfo.coinValue(coinValue: $0) }
        }

        viewItem.switchButtonEnabled = state.currencyValue != nil

        if let amountError = state.amountError {
            viewItem.hintInfo = .error(error: amountError)
        } else {
            switch state.inputType {
            case .coin:
                viewItem.hintInfo = state.currencyValue.map { HintInfo.amount(amountInfo: .currencyValue(currencyValue: $0)) }
            case .currency:
                viewItem.hintInfo = state.coinValue.map { HintInfo.amount(amountInfo: .coinValue(coinValue: $0)) }
            }
        }

        viewItem.feeInfo?.error = state.feeError

        if let address = state.address {
            if let addressError = state.addressError {
                viewItem.addressInfo = .invalidAddress(address: address, error: addressError)
            } else {
                viewItem.addressInfo = .address(address: address)
            }
        }

        let zeroAmount = state.coinValue.map { $0.value == 0 } ?? true
        viewItem.sendButtonEnabled = !zeroAmount && state.address != nil && state.amountError == nil && state.addressError == nil && state.feeError == nil

        return viewItem
    }

    func confirmationViewItem(forState state: SendState, coin: Coin) -> SendConfirmationViewItem? {
        guard let coinValue = state.coinValue else {
            return nil
        }
        guard let feeCoinValue = state.feeCoinValue else {
            return nil
        }
        guard let address = state.address else {
            return nil
        }

        let primaryAmountInfo: AmountInfo
        var stateFeeInfo: AmountInfo?
        var stateTotalInfo: AmountInfo?

        if state.inputType == .currency, let currencyValue = state.currencyValue {
            primaryAmountInfo = .currencyValue(currencyValue: CurrencyValue(currency: currencyValue.currency, value: -currencyValue.value))
        } else {
            primaryAmountInfo = .coinValue(coinValue: CoinValue(coinCode: coinValue.coinCode, value: -coinValue.value))
        }

        if let currencyValue = state.currencyValue, let feeCurrencyValue = state.feeCurrencyValue {
            stateFeeInfo = .currencyValue(currencyValue: feeCurrencyValue)
            stateTotalInfo = .currencyValue(currencyValue: CurrencyValue(currency: currencyValue.currency, value: currencyValue.value + feeCurrencyValue.value))
        } else {
            stateFeeInfo = .coinValue(coinValue: feeCoinValue)
            if coinValue.coinCode == feeCoinValue.coinCode {
                stateTotalInfo = .coinValue(coinValue: CoinValue(coinCode: coinValue.coinCode, value: coinValue.value + feeCoinValue.value))
            }
        }

        guard let feeInfo = stateFeeInfo else {
            return nil
        }

        let viewItem = SendConfirmationViewItem(
                coin: coin,
                primaryAmountInfo: primaryAmountInfo,
                address: address,
                feeInfo: feeInfo,
                totalInfo: stateTotalInfo
        )

        if state.inputType == .currency {
            viewItem.secondaryAmountInfo = .coinValue(coinValue: coinValue)
        } else {
            viewItem.secondaryAmountInfo = state.currencyValue.map { .currencyValue(currencyValue: $0) }
        }

        return viewItem
    }

}
