
import EvmKit
import Foundation
import MarketKit
import TronKit

class TronSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    let createdTransaction: CreatedTransactionResponse
    let transferIntent: TronTransferIntent?
    private let fees: [Fee]

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        createdTransaction: CreatedTransactionResponse,
        transferIntent: TronTransferIntent? = nil,
        fees: [Fee],
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.amountIn = amountIn
        self.createdTransaction = createdTransaction
        self.transferIntent = transferIntent
        self.fees = fees

        super.init(
            expectedBuyAmount: expectedAmountOut,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: estimatedTime,
            transactionError: transactionError,
            toAddress: toAddress,
            depositAddress: depositAddress,
            providerSwapId: providerSwapId
        )
    }

    override var feeData: FeeData? {
        .tron(fees: fees)
    }

    override func executable(tokenIn _: Token) -> ISwapExecutable {
        TronExecutable(created: createdTransaction, transferIntent: transferIntent)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        TronSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        TronSendHelper.feeFields(baseToken: baseToken, totalFees: fees.calculateTotalFees(), fees: fees, currency: currency, feeTokenRate: baseTokenRate)
    }
}
