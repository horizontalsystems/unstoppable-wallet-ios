import EvmKit
import Foundation
import MarketKit

class EvmSwapFinalQuote: SwapFinalQuote {
    let transactionData: TransactionData?
    let gasPrice: GasPrice?
    let evmFeeData: EvmFeeData?
    let nonce: Int?
    let mevProtectionAllowed: Bool

    init(
        expectedBuyAmount: Decimal,
        transactionData: TransactionData?,
        transactionError: Error? = nil,
        slippage: Decimal?,
        recipient: String?,
        estimatedTime: TimeInterval? = nil,
        gasPrice: GasPrice?,
        evmFeeData: EvmFeeData?,
        nonce: Int?,
        mevProtectionAllowed: Bool = false,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.transactionData = transactionData
        self.gasPrice = gasPrice
        self.evmFeeData = evmFeeData
        self.nonce = nonce
        self.mevProtectionAllowed = mevProtectionAllowed

        super.init(
            expectedBuyAmount: expectedBuyAmount,
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
        evmFeeData.map { .evm(evmFeeData: $0) }
    }

    override var canSwap: Bool {
        super.canSwap && gasPrice != nil && evmFeeData != nil && transactionData != nil
    }

    override func executable(tokenIn _: Token) -> ISwapExecutable {
        EvmExecutable(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: evmFeeData?.surchargedGasLimit,
            nonce: nonce,
            mevProtectionAllowed: mevProtectionAllowed,
            approval: nil
        )
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

        return fields
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        EvmSendHelper.feeFields(evmFeeData: evmFeeData, gasPrice: gasPrice, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
