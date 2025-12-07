import EvmKit
import Foundation
import MarketKit

class UnstoppableMultiSwapEvmConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let amountIn: Decimal
    let expectedAmountOut: Decimal
    let amountOutMin: Decimal
    let recipient: Address?
    let slippage: Decimal
    let transactionData: TransactionData
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, amountOutMin: Decimal, recipient: Address?, slippage: Decimal, transactionData: TransactionData, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.amountOutMin = amountOutMin
        self.recipient = recipient
        self.slippage = slippage
        self.transactionData = transactionData
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        expectedAmountOut
    }

    override func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        if let transactionError {
            return [caution(transactionError: transactionError, feeToken: baseToken)]
        }

        return cautions
    }

    override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        fields.append(.slippage(slippage))

        fields.append(
            .value(
                title: "swap.confirmation.minimum_received".localized,
                description: nil,
                appValue: AppValue(token: tokenOut, value: amountOutMin),
                currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: amountOutMin * $0) },
                formatFull: true
            )
        )

        return fields
    }
}
