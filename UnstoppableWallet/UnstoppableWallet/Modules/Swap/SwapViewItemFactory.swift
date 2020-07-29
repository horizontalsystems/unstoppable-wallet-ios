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

}

extension SwapViewItemFactory: ISwapViewItemFactory {

    func viewItem(coinIn: Coin, balance: Decimal?, coinOut: Coin?, path: SwapPath, tradeData: TradeData?) -> SwapViewItem {
        var estimatedAmount: String? = nil
        var error: Error? = nil

        var tokenOut: String? = nil

        let balanceValue = stringCoinValue(coin: coinIn, amount: balance)

        var minMaxTitle = "swap.max_min"
        var minMaxValue = "0"

        var executionPrice = ValueFormatter.instance.format(coinValue: CoinValue(coin: coinIn, value: 0))

        var impactColor = UIColor.themeGray
        var impactPrice = "0%"

        var buttonEnabled = false

        guard let coinOut = coinOut else {      // coin for swap not choose yet
            return SwapViewItem(estimatedField: path.toggle,
                    estimatedAmount: estimatedAmount,
                    error: error,
                    tokenIn: coinIn.code,
                    tokenOut: tokenOut,
                    availableBalance: balanceValue,
                    minMaxTitle: minMaxTitle,
                    minMaxValue: minMaxValue,
                    executionPriceValue: executionPrice,
                    priceImpactValue: impactPrice,
                    priceImpactColor: impactColor,
                    swapButtonEnabled: buttonEnabled)
        }

        tokenOut = coinOut.code
        minMaxTitle = path == .to ? "swap.maximum_paid" : "swap.minimum_got"

        guard let tradeData = tradeData else {      // trade data not calculated yet
            return SwapViewItem(estimatedField: path.toggle,
                    estimatedAmount: estimatedAmount,
                    error: error,
                    tokenIn: coinIn.code,
                    tokenOut: tokenOut,
                    availableBalance: balanceValue,
                    minMaxTitle: minMaxTitle,
                    minMaxValue: "0",
                    executionPriceValue: executionPrice,
                    priceImpactValue: impactPrice,
                    priceImpactColor: impactColor,
                    swapButtonEnabled: buttonEnabled)
        }

        buttonEnabled = true

        let maximumFractionDigits: Int
        let amount: Decimal?

        switch path {
        case .from:
            maximumFractionDigits = min(coinOut.decimal, 8)
            amount = tradeData.amountOut

            minMaxValue = stringCoinValue(coin: coinOut, amount: tradeData.amountOutMin) ?? minMaxValue
        case .to:
            maximumFractionDigits = min(coinIn.decimal, 8)
            amount = tradeData.amountIn

            if let balance = balance,
               let amount = amount,
               balance < amount {
                buttonEnabled = false
                error = SwapValidationError.insufficientBalance(availableBalance: balanceValue)
            }

            minMaxValue = stringCoinValue(coin: coinIn, amount: tradeData.amountInMax) ?? minMaxValue
        }

        coinFormatter.maximumFractionDigits = maximumFractionDigits
        if let amount = amount {
            estimatedAmount = coinFormatter.string(from: amount as NSNumber)
        }

        if let price = tradeData.executionPrice {
            executionPrice = ValueFormatter
                    .instance
                    .format(coinValue: CoinValue(coin: coinIn, value: 1 / price))
                    .map { [coinOut.code, $0].joined(separator: " = ") }
        }

        if let priceImpact = tradeData.priceImpact {
            if priceImpact <= 1 {
                impactColor = .themeRemus
            } else if priceImpact <= 5 {
                impactColor = .themeJacob
            } else {
                impactColor = .themeLucian
            }

            impactPrice = priceImpact.description + "%"
        }

        return SwapViewItem(estimatedField: path.toggle,
                estimatedAmount: estimatedAmount,
                error: error,
                tokenIn: coinIn.code,
                tokenOut: coinOut.code,
                availableBalance: balanceValue,
                minMaxTitle: minMaxTitle,
                minMaxValue: minMaxValue,
                executionPriceValue: executionPrice,
                priceImpactValue: impactPrice,
                priceImpactColor: impactColor,
                swapButtonEnabled: buttonEnabled)
    }

}