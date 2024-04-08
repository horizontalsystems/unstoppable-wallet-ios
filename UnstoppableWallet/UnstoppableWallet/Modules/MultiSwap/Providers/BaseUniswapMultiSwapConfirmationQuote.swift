import EvmKit
import Foundation
import MarketKit

class BaseUniswapMultiSwapConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let quote: BaseUniswapMultiSwapQuote
    let transactionData: TransactionData?
    let transactionError: Error?

    init(quote: BaseUniswapMultiSwapQuote, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.quote = quote
        self.transactionData = transactionData
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        quote.trade.amountOut ?? 0
    }

    override var canSwap: Bool {
        super.canSwap && transactionData != nil
    }

    override func cautions(feeToken: MarketKit.Token?) -> [CautionNew] {
        var cautions = super.cautions(feeToken: feeToken)

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: feeToken))
        }

        cautions.append(contentsOf: quote.cautions())

        return cautions
    }

    override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
        var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

        if let priceImpact = quote.trade.priceImpact, BaseUniswapMultiSwapProvider.PriceImpactLevel(priceImpact: priceImpact) != .negligible {
            fields.append(
                .levelValue(
                    title: "swap.price_impact".localized,
                    value: "\(priceImpact.rounded(decimal: 2))%",
                    level: BaseUniswapMultiSwapProvider.PriceImpactLevel(priceImpact: priceImpact).valueLevel
                )
            )
        }

        if let recipient = quote.recipient {
            fields.append(
                .address(
                    title: "swap.recipient".localized,
                    value: recipient.title,
                    blockchainType: tokenOut.blockchainType
                )
            )
        }

        let slippage = quote.tradeOptions.allowedSlippage

        if slippage != MultiSwapSlippage.default {
            fields.append(
                .levelValue(
                    title: "swap.slippage".localized,
                    value: "\(slippage.description)%",
                    level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                )
            )
        }

        let minAmountOut = amountOut * (1 - slippage / 100)

        fields.append(
            .value(
                title: "swap.confirmation.minimum_received".localized,
                description: nil,
                coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) },
                formatFull: true
            )
        )

        return fields
    }
}
