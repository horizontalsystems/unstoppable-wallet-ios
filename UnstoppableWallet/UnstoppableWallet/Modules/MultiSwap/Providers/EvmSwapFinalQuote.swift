import EvmKit
import Foundation
import MarketKit

class EvmSwapFinalQuote: SwapFinalQuote {
    let transactionData: TransactionData?
    let gasPrice: GasPrice?
    let evmFeeData: EvmFeeData?
    let nonce: Int?

    init(
        expectedBuyAmount: Decimal,
        transactionData: TransactionData?,
        transactionError: Error? = nil,
        slippage: Decimal?,
        recipient: String?,
        estimatedTime: TimeInterval? = nil,
        gasPrice: GasPrice?,
        evmFeeData: EvmFeeData?,
        nonce: Int?
    ) {
        self.transactionData = transactionData
        self.gasPrice = gasPrice
        self.evmFeeData = evmFeeData
        self.nonce = nonce

        super.init(expectedBuyAmount: expectedBuyAmount, slippage: slippage, recipient: recipient, estimatedTime: estimatedTime, transactionError: transactionError)
    }

    override var feeData: FeeData? {
        evmFeeData.map { .evm(evmFeeData: $0) }
    }

    override var canSwap: Bool {
        super.canSwap && gasPrice != nil && evmFeeData != nil && transactionData != nil
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        EvmSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if let nonce {
            fields.append(
                .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
            )
        }

        fields.append(contentsOf: EvmSendHelper.feeFields(evmFeeData: evmFeeData, gasPrice: gasPrice, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
