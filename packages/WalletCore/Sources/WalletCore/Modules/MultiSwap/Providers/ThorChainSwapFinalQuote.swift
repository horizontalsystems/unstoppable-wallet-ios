import Foundation
import MarketKit
import ThorChainKit

class ThorChainSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    private let kind: ThorChainExecutable.Kind
    private let memo: String
    private let fee: Decimal?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        kind: ThorChainExecutable.Kind,
        memo: String,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String
    ) {
        self.amountIn = amountIn
        self.kind = kind
        self.memo = memo
        self.fee = fee

        super.init(
            expectedBuyAmount: expectedAmountOut,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: estimatedTime,
            transactionError: transactionError,
            toAddress: toAddress
        )
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }

    override func executable(tokenIn: Token) -> ISwapExecutable {
        ThorChainExecutable(token: tokenIn, kind: kind, amount: amountIn, memo: memo)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        ThorChainSendHelper.caution(transactionError, feeToken: baseToken)
    }
}
