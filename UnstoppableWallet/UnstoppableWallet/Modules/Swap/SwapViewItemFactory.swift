import UniswapKit

class SwapViewItemFactory {

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private func stringCoinValue(coin: Coin, amount: Decimal?) -> String? {
        guard let amount = amount else {
            return nil
        }
        return ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: amount))
    }

    private func minMaxTitle(type: TradeType) -> String {
        type == .exactOut ? "swap.maximum_paid" : "swap.minimum_got"
    }

    private func value(executionPrice: Decimal?, coinIn: Coin?, coinOut: Coin?) -> String? {
        guard let coinIn = coinIn else {
            return nil
        }
        guard let price = executionPrice,
              let coinOut = coinOut else {

            return ValueFormatter.instance.format(coinValue: CoinValue(coin: coinIn, value: 0))
        }
        let value = price.isZero ? 0 : 1 / price
        return ValueFormatter
                .instance
                .format(coinValue: CoinValue(coin: coinIn, value: value))
                .map {
                    [coinOut.code, $0].joined(separator: " = ")
                }
    }

    private func data(impactPrice: Decimal?) -> (String, UIColor) {
        guard let priceImpact = impactPrice else {
            return ("0%", .themeGray)
        }

        let impactColor: UIColor

        if priceImpact <= 1 {
            impactColor = .themeRemus
        } else if priceImpact <= 5 {
            impactColor = .themeJacob
        } else {
            impactColor = .themeLucian
        }

        return (priceImpact.description + "%", impactColor)
    }

    private func estimatedAmountValue(coinIn: Coin, coinOut: Coin, tradeData: TradeData?) -> String? {
        guard let tradeData = tradeData else {
            return nil
        }

        let maximumFractionDigits: Int
        let amount: Decimal?

        switch tradeData.type {
        case .exactIn:
            maximumFractionDigits = min(coinOut.decimal, 8)
            amount = tradeData.amountOut
        case .exactOut:
            maximumFractionDigits = min(coinIn.decimal, 8)
            amount = tradeData.amountIn
        }
        coinFormatter.maximumFractionDigits = maximumFractionDigits

        return amount.flatMap { coinFormatter.string(from: $0 as NSNumber) }
    }

    private func minMaxValue(coinIn: Coin, coinOut: Coin, tradeData: TradeData) -> String? {
        switch tradeData.type {
        case .exactIn:
            return stringCoinValue(coin: coinOut, amount: tradeData.amountOutMin)
        case .exactOut:
            return stringCoinValue(coin: coinIn, amount: tradeData.amountInMax)
        }
    }

    private func handle(tradeData: DataStatus<TradeData>?) -> DataStatus<TradeData>? {
        if let tradeData = tradeData, case .failed(let error) = tradeData {

            if let error = error, case UniswapKit.Kit.TradeError.zeroAmount = error {
                return nil
            }
        }

        return tradeData
    }

    func validAmount(coin: Coin, amountIn: Decimal?, balance: Decimal) throws -> Bool {
        guard let amountIn = amountIn, !amountIn.isZero else {
            return false
        }
        if amountIn > balance {
            throw SwapValidationError.insufficientBalance(availableBalance: CoinValue(coin: coin, value: balance))
        }

        return true
    }

    func enableApprove(allowance: DataStatus<Decimal>, amountIn: Decimal?) -> Bool {
        amountIn != nil && allowance.data != nil
    }

    func enableButton(coin: Coin, amountIn: Decimal?, balance: Decimal, allowance: DataStatus<Decimal>?) throws -> Bool {
        var enabled = try validAmount(coin: coin, amountIn: amountIn, balance: balance)

        if let allowance = allowance {
            enabled = enabled && enableApprove(allowance: allowance, amountIn: amountIn)
        }

        return enabled
    }


}

extension SwapViewItemFactory: ISwapViewItemFactory {

    func viewItem(coinIn: Coin, balance: Decimal?, coinOut: Coin?, type: TradeType, allowance: DataStatus<Decimal>?, tradeData: DataStatus<TradeData>?, state: SwapProcessState) -> SwapModule.ViewItem {
        let balanceValue = stringCoinValue(coin: coinIn, amount: balance)
        let tokenOut = coinOut?.code

        let allowanceValue = allowance?.flatMap { stringCoinValue(coin: coinIn, amount: $0) }

        guard let coinOut = coinOut,
              let balance = balance,
              let tradeData = handle(tradeData: tradeData) else {      // trade data not exist

            return SwapModule.ViewItem(exactType: type,
                    estimatedAmount: nil,
                    tokenIn: coinIn.code,
                    tokenOut: tokenOut,
                    balance: balanceValue,
                    balanceError: nil,
                    allowance: allowanceValue,
                    swapAreaItem: nil)
        }

        let amount = estimatedAmountValue(coinIn: coinIn, coinOut: coinOut, tradeData: tradeData.data)

        let enabled: Bool
        var balanceError: Error?
        if state == .approving {
            enabled = false
        } else {
            do {
                enabled = try enableButton(coin: coinIn, amountIn: tradeData.data?.amountIn, balance: balance, allowance: allowance)
            } catch {
                enabled = false
                balanceError = error
            }
        }

        let swapAreaItem = tradeData.map { (data: TradeData) -> SwapModule.SwapAreaViewItem in
            let minMaxTitle = self.minMaxTitle(type: type)
            let minMaxValue = self.minMaxValue(coinIn: coinIn, coinOut: coinOut, tradeData: data)
            let price = self.value(executionPrice: data.executionPrice, coinIn: coinIn, coinOut: coinOut)
            let impactData = self.data(impactPrice: data.priceImpact)

            return SwapModule.SwapAreaViewItem(minMaxItem: AdditionalViewItem(title: minMaxTitle, value: minMaxValue),
                    executionPriceItem: AdditionalViewItem(title: "swap.price", value: price),
                    priceImpactItem: AdditionalViewItem(title: "swap.price_impact", value: impactData.0, customColor: impactData.1),
                    buttonTitle: state.title,
                    buttonEnabled: enabled)
        }

        return SwapModule.ViewItem(exactType: type,
                estimatedAmount: amount,
                tokenIn: coinIn.code,
                tokenOut: tokenOut,
                balance: balanceValue,
                balanceError: balanceError,
                allowance: allowanceValue,
                swapAreaItem: swapAreaItem)

    }

}

extension SwapViewItemFactory: ISwapConfirmationViewItemFactory {

    func viewItem(coinIn: Coin, coinOut: Coin, tradeData: TradeData) -> SwapConfirmationModule.ViewItem {
        let payValue = stringCoinValue(coin: coinIn, amount: tradeData.amountIn)
        let getValue = stringCoinValue(coin: coinOut, amount: tradeData.amountOut)

        let maxMinTitle = self.minMaxTitle(type: tradeData.type)

        let maxMinValue: String?
        switch tradeData.type {
        case .exactIn:
            maxMinValue = stringCoinValue(coin: coinOut, amount: tradeData.amountOutMin)
        case .exactOut:
            maxMinValue = stringCoinValue(coin: coinIn, amount: tradeData.amountInMax)
        }

        let executionPrice = value(executionPrice: tradeData.executionPrice, coinIn: coinIn, coinOut: coinOut)
        let impactData = data(impactPrice: tradeData.priceImpact)

        let additionalItems = [
            SwapConfirmationModule.AdditionalDataItem(title: maxMinTitle, value: maxMinValue, color: nil),
            SwapConfirmationModule.AdditionalDataItem(title: "swap.price", value: executionPrice, color: nil),
            SwapConfirmationModule.AdditionalDataItem(title: "swap.price_impact", value: impactData.0, color: impactData.1),
            SwapConfirmationModule.AdditionalDataItem(title: "swap.fee", value: "-", color: nil),
            SwapConfirmationModule.AdditionalDataItem(title: "swap.transaction_fee", value: "-", color: nil)
        ]

        return SwapConfirmationModule.ViewItem(
                payTitle: coinIn.title,
                payValue: payValue,
                getTitle: coinOut.title,
                getValue: getValue,
                additionalDataItems: additionalItems
        )
    }

}
