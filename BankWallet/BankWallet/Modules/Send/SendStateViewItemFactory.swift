class SendStateViewItemFactory: ISendStateViewItemFactory {

    func viewItem(forState state: SendState) -> SendStateViewItem {
        var viewItem = SendStateViewItem()

        switch state.inputType {
        case .coin:
            viewItem.amountInfo = state.coinValue.map { AmountInfo.coinValue(coinValue: $0) }
            viewItem.primaryFeeInfo = state.feeCoinValue.map { AmountInfo.coinValue(coinValue: $0) }
            viewItem.secondaryFeeInfo = state.feeCurrencyValue.map { AmountInfo.currencyValue(currencyValue: $0) }
        case .currency:
            viewItem.amountInfo = state.currencyValue.map { AmountInfo.currencyValue(currencyValue: $0) }
            viewItem.primaryFeeInfo = state.feeCurrencyValue.map { AmountInfo.currencyValue(currencyValue: $0) }
            viewItem.secondaryFeeInfo = state.feeCoinValue.map { AmountInfo.coinValue(coinValue: $0) }
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

        if let address = state.address {
            if let addressError = state.addressError {
                viewItem.addressInfo = .invalidAddress(address: address, error: addressError)
            } else {
                viewItem.addressInfo = .address(address: address)
            }
        }

        let zeroAmount = state.coinValue.map { $0.value == 0 } ?? true
        viewItem.sendButtonEnabled = !zeroAmount && state.address != nil && state.amountError == nil && state.addressError == nil

        return viewItem
    }

}
