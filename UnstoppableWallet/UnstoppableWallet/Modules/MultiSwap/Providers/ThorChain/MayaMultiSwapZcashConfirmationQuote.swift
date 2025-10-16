import BitcoinCore
import Foundation
import MarketKit
import ZcashLightClientKit

class MayaMultiSwapZcashConfirmationQuote: IMultiSwapConfirmationQuote {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?
    let amountIn: Decimal
    let slippage: Decimal
    let totalFeeRequired: Zatoshi
    let transactionError: Error?

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, amountIn: Decimal, totalFeeRequired: Zatoshi, slippage: Decimal, transactionError: Error?) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.amountIn = amountIn
        self.totalFeeRequired = totalFeeRequired
        self.slippage = slippage
        self.transactionError = transactionError
    }

    var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    var feeData: FeeData? {
        .zcash(fee: totalFeeRequired.decimalValue.decimalValue)
    }

    var canSwap: Bool {
        transactionError == nil
    }

    func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        transactionError.map { error in
            [caution(transactionError: error, feeToken: baseToken)]
        } ?? []
    }

    func priceSectionFields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken _: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate: Decimal?, baseTokenRate _: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        fields.append(.slippage(slippage))

        let minAmountOut = amountOut * (1 - slippage / 100)

        fields.append(
            .value(
                title: "swap.confirmation.minimum_received".localized,
                description: nil,
                appValue: AppValue(token: tokenOut, value: minAmountOut),
                currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) },
                formatFull: true
            )
        )

        return fields
    }

    func otherSections(tokenIn _: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendDataSection] {
        var sections = [SendDataSection]()

        var feeFields = [SendField]()

        if swapQuote.affiliateFee > 0 {
            feeFields.append(
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
            feeFields.append(
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
            feeFields.append(
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

        if !feeFields.isEmpty {
            sections.append(.init(feeFields))
        }

        if let tokenOutRate,
           let feeAmountData = amountData(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate),
           let feeCurrencyValue = feeAmountData.currencyValue
        {
            let totalFee = feeCurrencyValue.value + (swapQuote.affiliateFee + swapQuote.liquidityFee + swapQuote.outboundFee) * tokenOutRate
            let currencyValue = CurrencyValue(currency: currency, value: totalFee)

            if let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
                sections.append(
                    .init([
                        .levelValue(
                            title: "swap.total_fee".localized,
                            value: formatted,
                            level: .regular
                        ),
                    ])
                )
            }
        }

        return sections
    }

    private func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        let fee = totalFeeRequired.decimalValue.decimalValue
        return AmountData(
            appValue: AppValue(token: feeToken, value: fee),
            currencyValue: feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }
        )
    }

    private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let error = transactionError as? BitcoinCoreErrors.SendValueErrors {
            switch error {
            case .notEnough:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(feeToken.coin.code)

            case let .dust(dustAmount):
                title = "send.amount_error.minimum_amount.title".localized
                text = "send.amount_error.minimum_amount.description".localized("\(dustAmount) zatoshis")

            default:
                title = "Send Info error"
                text = "Send Info error description"
            }
        } else {
            title = "alert.error".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }
}
