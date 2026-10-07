import Foundation
import MarketKit
import TonKit

class TonSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    let transactionParam: SendTransactionParam?
    // plain transfer built locally for a USwap transfer route (no server transaction)
    let transfer: TonTransferExecution?
    private let fee: Decimal?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        transactionParam: SendTransactionParam?,
        transfer: TonTransferExecution? = nil,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.amountIn = amountIn
        self.transactionParam = transactionParam
        self.transfer = transfer
        self.fee = fee

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

    private var kind: TonExecutable.Kind? {
        if let transactionParam {
            return .param(transactionParam)
        }
        if let transfer {
            return .transfer(transfer)
        }
        return nil
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil && kind != nil
    }

    override func buildExecutable(tokenIn: Token) -> ISwapExecutable {
        TonExecutable(token: tokenIn, kind: kind)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        TonSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        TonSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
