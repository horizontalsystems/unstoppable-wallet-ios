import BitcoinCore
import Foundation
import MarketKit
import ZcashLightClientKit

class MayaMultiSwapZcashConfirmationQuote: IMultiSwapConfirmationQuote {
    let swapQuote: MayaMultiSwapProvider.SwapQuote
    let recipient: Address?
    let amountIn: Decimal
    let slippage: Decimal
    let totalFeeRequired: Zatoshi
    let transactionError: Error?

    init(swapQuote: MayaMultiSwapProvider.SwapQuote, recipient: Address?, amountIn: Decimal, totalFeeRequired: Zatoshi, slippage: Decimal, transactionError: Error?) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.amountIn = amountIn
        self.totalFeeRequired = totalFeeRequired
        self.slippage = slippage
        self.transactionError = transactionError
    }

    var amountOut: Decimal {
        swapQuote.quote.expectedAmountOut
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

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken _: MarketKit.Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate _: Decimal?) -> [SendField] {
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

        return fields
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
