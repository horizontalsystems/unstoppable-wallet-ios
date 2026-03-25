import Foundation
import MarketKit

class SolanaSwapFinalQuote: SwapFinalQuote {
    let rawTransaction: Data
    private let fee: Decimal?

    init(
        rawTransaction: Data,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String
    ) {
        self.rawTransaction = rawTransaction
        self.fee = fee

        super.init(expectedBuyAmount: expectedAmountOut, slippage: slippage, recipient: recipient, estimatedTime: estimatedTime, transactionError: transactionError, toAddress: toAddress)
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        let title: String
        let text: String

        if let solanaError = transactionError as? SolanaSendHandler.TransactionError {
            switch solanaError {
            case let .insufficientSolBalance(balance):
                let appValue = AppValue(token: baseToken, value: balance)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if let fee {
            let appValue = AppValue(token: baseToken, value: fee)
            let currencyValue = baseTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

            fields.append(
                .fee(
                    title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                    amountData: .init(appValue: appValue, currencyValue: currencyValue)
                )
            )
        }

        return fields
    }
}
