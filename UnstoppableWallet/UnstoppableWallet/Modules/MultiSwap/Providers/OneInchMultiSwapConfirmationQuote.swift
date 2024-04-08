import EvmKit
import Foundation
import MarketKit
import OneInchKit

class OneInchMultiSwapConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let quote: OneInchMultiSwapQuote
    let swap: Swap?
    let insufficientFeeBalance: Bool

    init(quote: OneInchMultiSwapQuote, swap: Swap?, insufficientFeeBalance: Bool, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.quote = quote
        self.swap = swap
        self.insufficientFeeBalance = insufficientFeeBalance

        super.init(gasPrice: swap?.transaction.gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        swap?.amountOut ?? quote.quote.amountOut ?? 0
    }

    override var canSwap: Bool {
        super.canSwap && swap != nil && !insufficientFeeBalance
    }

    override func cautions(feeToken: MarketKit.Token?) -> [CautionNew] {
        var cautions = super.cautions(feeToken: feeToken)

        if insufficientFeeBalance {
            cautions.append(
                .init(
                    title: "fee_settings.errors.insufficient_balance".localized,
                    text: "ethereum_transaction.error.insufficient_balance_with_fee".localized(feeToken?.coin.code ?? ""),
                    type: .error
                )
            )
        }

        cautions.append(contentsOf: quote.cautions())

        return cautions
    }

    override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
        var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

        if let recipient = quote.recipient {
            fields.append(
                .address(
                    title: "swap.recipient".localized,
                    value: recipient.title,
                    blockchainType: tokenOut.blockchainType
                )
            )
        }

        let slippage = quote.slippage

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
