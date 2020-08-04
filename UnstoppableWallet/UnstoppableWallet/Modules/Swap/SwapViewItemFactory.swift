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
                .map { [coinOut.code, $0].joined(separator: " = ") }
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

}

extension SwapViewItemFactory: ISwapViewItemFactory {

    func viewItem(coinIn: Coin, balance: Decimal?, coinOut: Coin?, type: TradeType, tradeData: TradeData?) -> SwapModule.ViewItem {
        var estimatedAmount: String? = nil
        var error: Error? = nil

        let balanceValue = stringCoinValue(coin: coinIn, amount: balance)

        let tokenOut = coinOut?.code

        var minMaxTitle = "swap.max_min"
        if coinOut != nil {
            minMaxTitle = self.minMaxTitle(type: type)
        }

        var minMaxValue = "0"

        var buttonEnabled = false

        guard let coinOut = coinOut,
              let tradeData = tradeData else {      // trade data not calculated yet

            return SwapModule.ViewItem(exactType: type,
                    estimatedAmount: estimatedAmount,
                    error: error,
                    tokenIn: coinIn.code,
                    tokenOut: tokenOut,
                    availableBalance: balanceValue,
                    minMaxTitle: minMaxTitle,
                    minMaxValue: minMaxValue,
                    executionPriceValue: value(executionPrice: nil, coinIn: coinIn, coinOut: nil),
                    priceImpactValue: "0%",
                    priceImpactColor: .themeGray,
                    swapButtonEnabled: buttonEnabled)
        }

        buttonEnabled = true

        let maximumFractionDigits: Int
        let amount: Decimal?

        if let balance = balance,
           let amount = tradeData.amountIn,
           balance < amount {
            buttonEnabled = false
            error = SwapValidationError.insufficientBalance(availableBalance: balanceValue)
        }
        if (tradeData.amountIn?.isZero ?? true) ||
           (tradeData.amountOut?.isZero ?? true) {
            buttonEnabled = false
        }

        switch type {
        case .exactIn:
            maximumFractionDigits = min(coinOut.decimal, 8)
            amount = tradeData.amountOut

            minMaxValue = stringCoinValue(coin: coinOut, amount: tradeData.amountOutMin) ?? minMaxValue
        case .exactOut:
            maximumFractionDigits = min(coinIn.decimal, 8)
            amount = tradeData.amountIn

            minMaxValue = stringCoinValue(coin: coinIn, amount: tradeData.amountInMax) ?? minMaxValue
        }

        coinFormatter.maximumFractionDigits = maximumFractionDigits
        if let amount = amount {
            estimatedAmount = coinFormatter.string(from: amount as NSNumber)
        }

        let price = value(executionPrice: tradeData.executionPrice, coinIn: coinIn, coinOut: coinOut)
        let impactData = data(impactPrice: tradeData.priceImpact)

        return SwapModule.ViewItem(exactType: type,
                estimatedAmount: estimatedAmount,
                error: error,
                tokenIn: coinIn.code,
                tokenOut: tokenOut,
                availableBalance: balanceValue,
                minMaxTitle: minMaxTitle,
                minMaxValue: minMaxValue,
                executionPriceValue: price,
                priceImpactValue: impactData.0,
                priceImpactColor: impactData.1,
                swapButtonEnabled: buttonEnabled)
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
