import UniswapKit

class SwapViewItemFactory {
}

extension SwapViewItemFactory: ISwapViewItemFactory {

    func viewItem(coinIn: Coin, coinOut: Coin?, path: SwapPath, tradeData: TradeData?) -> SwapViewItem {
        guard let coinOut = coinOut else {      // coin for swap not choose yet
            return SwapViewItem(estimatedField: path.estimated,
                        estimatedAmount: nil,
                        tokenIn: coinIn.code,
                        tokenOut: "Token",
                        availableBalance: nil,
                        minMaxTitle: "swap.max_min".localized,
                        minMaxValue: "0",
                        executionPriceValue: "0",
                        priceImpactValue: "0%",
                        swapButtonEnabled: false)
        }

        let minMaxTitle = path == .to ? "swap.maximum_paid" : "swap.minimum_got"
        guard let tradeData = tradeData else {      // trade data not calculated yet
            return SwapViewItem(estimatedField: path.estimated,
                    estimatedAmount: nil,
                    tokenIn: coinIn.code,
                    tokenOut: coinOut.code,
                    availableBalance: nil,
                    minMaxTitle: minMaxTitle,
                    minMaxValue: "0",
                    executionPriceValue: "0",
                    priceImpactValue: "0%",
                    swapButtonEnabled: false)
        }
        var minMaxValue: String?

        switch path {
        case .from:
            if let minMaxDecimalValue = tradeData.amountOutMin {
                minMaxValue = [minMaxDecimalValue.description, coinOut.title].joined(separator: " ")
            }
        case .to:
            if let minMaxDecimalValue = tradeData.amountInMax {
                minMaxValue = [minMaxDecimalValue.description, coinIn.title].joined(separator: " ")
            }
        }

        var executionPriceValue = ["0", coinIn.title].joined(separator: " ")
        if let executionPrice = tradeData.executionPrice {
            executionPriceValue = coinOut.title + " = " + [executionPrice.description, coinIn.title].joined(separator: " ")
        }

        return SwapViewItem(estimatedField: path.estimated,
                estimatedAmount: nil,
                tokenIn: coinIn.code,
                tokenOut: coinOut.code,
                availableBalance: nil,
                minMaxTitle: minMaxTitle,
                minMaxValue: minMaxValue ?? "0",
                executionPriceValue: executionPriceValue,
                priceImpactValue: tradeData.priceImpact?.description ?? "0%",
                swapButtonEnabled: false)

//        let fromLabel = "From:\(tradeType == .exactOut ? " (estimated)" : "")"
//        let toLabel = "To:\(tradeType == .exactIn ? " (estimated)" : "")"
//
//        swapButton.isEnabled = tradeData != nil
//
//        if let tradeData = tradeData {
//            switch tradeData.type {
//            case .exactIn:
//                minMaxLabel.text = tradeData.amountOutMin.map { "Minimum Received: \($0.description) \(tokenCoin(token: toToken))" }
//            case .exactOut:
//                minMaxLabel.text = tradeData.amountInMax.map { "Maximum Sold: \($0.description) \(tokenCoin(token: fromToken))" }
//            }
//
//            executionPriceLabel.text = tradeData.executionPrice.map { "Execution Price: \($0.description) \(tokenCoin(token: toToken)) per \(tokenCoin(token: fromToken))" }
//            midPriceLabel.text = tradeData.midPrice.map { "Mid Price: \($0.description) \(tokenCoin(token: toToken)) per \(tokenCoin(token: fromToken))" }
//
//            priceImpactLabel.text = tradeData.priceImpact.map { "Price Impact: \($0.description)%" }
//
//            pathLabel.text = "Route: \(pathString(path: tradeData.path))"
//        } else {
//            minMaxLabel.text = nil
//            executionPriceLabel.text = nil
//            midPriceLabel.text = nil
//            priceImpactLabel.text = nil
//            pathLabel.text = nil
//        }

    }

}