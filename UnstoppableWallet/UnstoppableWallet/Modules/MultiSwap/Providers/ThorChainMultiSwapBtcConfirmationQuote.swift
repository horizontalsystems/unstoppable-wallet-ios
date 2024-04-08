import Foundation
import MarketKit

class ThorChainMultiSwapBtcConfirmationQuote: BaseSendBtcData, IMultiSwapConfirmationQuote {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?
    let slippage: Decimal

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, slippage: Decimal, satoshiPerByte: Int?, bytes: Int?) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.slippage = slippage

        super.init(satoshiPerByte: satoshiPerByte, bytes: bytes)
    }

    var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    var feeData: FeeData? {
        bytes.map { .bitcoin(bytes: $0) }
    }

    var canSwap: Bool {
        satoshiPerByte != nil && bytes != nil
    }

    func cautions(feeToken _: MarketKit.Token?) -> [CautionNew] {
        var cautions = [CautionNew]()

        switch MultiSwapSlippage.validate(slippage: slippage) {
        case .none: ()
        case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
        }

        return cautions
    }

    func priceSectionFields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, feeToken _: MarketKit.Token?, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate _: Decimal?) -> [SendConfirmField] {
        var fields = [SendConfirmField]()

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

    func otherSections(tokenIn _: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate _: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
        var sections = [[SendConfirmField]]()

        var feeFields = [SendConfirmField]()

        if let feeToken {
            feeFields.append(contentsOf: super.feeFields(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate))
        }

        if swapQuote.affiliateFee > 0 {
            feeFields.append(
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
            feeFields.append(
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
            feeFields.append(
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

        if let feeToken, let tokenOutRate,
           let feeAmountData = amountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate),
           let feeCurrencyValue = feeAmountData.currencyValue
        {
            let totalFee = feeCurrencyValue.value + (swapQuote.affiliateFee + swapQuote.liquidityFee + swapQuote.outboundFee) * tokenOutRate
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

        if let tokenOutRate {
            let totalFee = (swapQuote.affiliateFee + swapQuote.liquidityFee + swapQuote.outboundFee) * tokenOutRate
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
}
