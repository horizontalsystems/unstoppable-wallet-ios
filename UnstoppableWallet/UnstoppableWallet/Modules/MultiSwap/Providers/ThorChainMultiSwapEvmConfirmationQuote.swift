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

    override func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
        }

        switch MultiSwapSlippage.validate(slippage: slippage) {
        case .none: ()
        case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
        }

        return cautions
    }

    override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

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

        return fields
    }

    override func otherSections(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [[SendField]] {
        var sections = super.otherSections(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if let tokenOutRate, let evmFeeData,
           let evmFeeAmountData = evmFeeData.totalAmountData(gasPrice: gasPrice, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate),
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

    override func additionalFeeFields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if swapQuote.affiliateFee > 0 {
            fields.append(
                .value(
                    title: "swap.affiliate_fee".localized,
                    description: nil,
                    appValue: AppValue(token: tokenOut, value: swapQuote.affiliateFee),
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
                    appValue: AppValue(token: tokenOut, value: swapQuote.liquidityFee),
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
                    appValue: AppValue(token: tokenOut, value: swapQuote.outboundFee),
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
