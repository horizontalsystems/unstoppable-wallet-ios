import BitcoinCore
import Foundation
import MarketKit
import ZcashLightClientKit

class USwapMultiSwapZcashConfirmationQuote: IMultiSwapConfirmationQuote {
    let amountIn: Decimal
    let expectedAmountOut: Decimal
    let amountOutMin: Decimal
    let recipient: Address?
    let slippage: Decimal
    let totalFeeRequired: Zatoshi?
    let proposal: Proposal?
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, amountOutMin: Decimal, recipient: Address?, slippage: Decimal, totalFeeRequired: Zatoshi?, proposal: Proposal?, transactionError: Error?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.amountOutMin = amountOutMin
        self.recipient = recipient
        self.slippage = slippage
        self.totalFeeRequired = totalFeeRequired
        self.proposal = proposal
        self.transactionError = transactionError
    }

    var amountOut: Decimal {
        expectedAmountOut
    }

    var feeData: FeeData? {
        totalFeeRequired.map { .zcash(fee: $0.decimalValue.decimalValue) }
    }

    var canSwap: Bool {
        proposal != nil && transactionError == nil
    }

    func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        transactionError.map { error in
            [caution(transactionError: error, feeToken: baseToken)]
        } ?? []
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        let minAmountOut = amountOut * (1 - slippage / 100)
        if let minRecieve = SendField.minRecieve(token: tokenOut, value: minAmountOut) {
            fields.append(minRecieve)
        }

        if let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        if let amountData = amountData(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate) {
            fields.append(
                .value(
                    title: "fee_settings.network_fee".localized,
                    description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                    appValue: amountData.appValue,
                    currencyValue: amountData.currencyValue,
                    formatFull: true
                )
            )
        }

        return fields
    }

    private func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let totalFeeRequired else {
            return nil
        }

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
