import EvmKit
import Foundation
import MarketKit

class ThorChainMultiSwapEvmConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?
    let slippage: Decimal
    let transactionData: TransactionData
    let transactionError: Error?

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, slippage: Decimal, transactionData: TransactionData, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.slippage = slippage
        self.transactionData = transactionData
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    override func cautions(feeToken: MarketKit.Token?) -> [CautionNew] {
        var cautions = super.cautions(feeToken: feeToken)

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: feeToken))
        }

        switch MultiSwapSlippage.validate(slippage: slippage) {
        case .none: ()
        case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
        }

        return cautions
    }

    override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
        var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

        if let recipient {
            fields.append(
                .address(
                    title: "swap.recipient".localized,
                    value: recipient.title,
                    blockchainType: tokenOut.blockchainType
                )
            )
        }

        if slippage != MultiSwapSlippage.default {
            fields.append(
                .levelValue(
                    title: "swap.slippage".localized,
                    value: "\(slippage.description)%",
                    level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                )
            )
        }

//            let minAmountOut = amountOut * (1 - slippage / 100)
//
//            fields.append(
//                .value(
//                    title: "swap.confirmation.minimum_received".localized,
//                    description: nil,
//                    coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
//                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) },
//                    formatFull: true
//                )
//            )

        return fields
    }

    override func otherSections(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
        var sections = super.otherSections(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

        if let feeToken, let tokenOutRate, let evmFeeData,
           let evmFeeAmountData = evmFeeData.totalAmountData(gasPrice: gasPrice, feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate),
           let evmFeeCurrencyValue = evmFeeAmountData.currencyValue
        {
            let totalFee = evmFeeCurrencyValue.value + (swapQuote.affiliateFee + swapQuote.liquidityFee + swapQuote.outboundFee) * tokenOutRate
            let currencyValue = CurrencyValue(currency: currency, value: totalFee)

            if let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
                sections.append(
                    [
                        .levelValue(
                            title: "swap.total_fee".localized,
                            value: formatted,
                            level: .regular
                        ),
                    ]
                )
            }
        }

        return sections
    }

    override func additionalFeeFields(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [SendConfirmField] {
        var fields = super.additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

        if swapQuote.affiliateFee > 0 {
            fields.append(
                .value(
                    title: "swap.affiliate_fee".localized,
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: swapQuote.affiliateFee),
                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: swapQuote.affiliateFee * $0) },
                    formatFull: true
                )
            )
        }

        if swapQuote.liquidityFee > 0 {
            fields.append(
                .value(
                    title: "swap.liquidity_fee".localized,
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: swapQuote.liquidityFee),
                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: swapQuote.liquidityFee * $0) },
                    formatFull: true
                )
            )
        }

        if swapQuote.outboundFee > 0 {
            fields.append(
                .value(
                    title: "swap.outbound_fee".localized,
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: swapQuote.outboundFee),
                    currencyValue: tokenOutRate.map {
                        CurrencyValue(currency: currency, value: swapQuote.outboundFee * $0)
                    },
                    formatFull: true
                )
            )
        }

        return fields
    }
}
