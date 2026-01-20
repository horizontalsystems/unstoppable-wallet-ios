import Foundation
import MarketKit
import MoneroKit

class MoneroSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    let amount: MoneroSendAmount
    let address: String
    let memo: String?
    private let token: Token
    let priority: SendPriority
    private let fee: Decimal?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        amount: MoneroSendAmount,
        address: String,
        memo: String?,
        token: Token,
        priority: SendPriority,
        fee: Decimal?,
        transactionError: Error?
    ) {
        self.amountIn = amountIn
        self.amount = amount
        self.address = address
        self.memo = memo
        self.token = token
        self.priority = priority
        self.fee = fee

        super.init(expectedBuyAmount: expectedAmountOut, slippage: slippage, recipient: recipient, transactionError: transactionError)
    }

    override var feeData: FeeData? {
        .monero(amount: amount, address: address)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        MoneroSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        fields.append(contentsOf: MoneroSendHelper.feeFields(
            fee: fee,
            feeToken: baseToken,
            currency: currency,
            feeTokenRate: baseTokenRate,
            priority: priority
        ))

        return fields
    }
}
