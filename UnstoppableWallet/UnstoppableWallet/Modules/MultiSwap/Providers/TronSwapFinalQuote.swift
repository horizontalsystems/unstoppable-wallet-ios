
import EvmKit
import Foundation
import MarketKit
import TronKit

class TronSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    let createdTransaction: CreatedTransactionResponse
    private let fees: [Fee]

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: String?, slippage: Decimal?, createdTransaction: CreatedTransactionResponse, fees: [Fee], transactionError: Error?) {
        self.amountIn = amountIn
        self.createdTransaction = createdTransaction
        self.fees = fees

        super.init(expectedBuyAmount: expectedAmountOut, slippage: slippage, recipient: recipient, transactionError: transactionError)
    }

    override var feeData: FeeData? {
        .tron(fees: fees)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        TronSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        fields.append(contentsOf: TronSendHelper.feeFields(baseToken: baseToken, totalFees: fees.calculateTotalFees(), fees: fees, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
