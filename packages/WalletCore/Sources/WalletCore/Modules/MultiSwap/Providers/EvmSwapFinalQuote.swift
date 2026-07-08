import EvmKit
import Foundation
import MarketKit

public class EvmSwapFinalQuote: SwapFinalQuote {
    let transactionData: TransactionData?
    let gasPrice: GasPrice?
    let evmFeeData: EvmFeeData?
    let nonce: Int?
    let mevProtectionAllowed: Bool
    let approval: SwapApproval?

    public init(
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
        approval: SwapApproval? = nil,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.transactionData = transactionData
        self.gasPrice = gasPrice
        self.evmFeeData = evmFeeData
        self.nonce = nonce
        self.mevProtectionAllowed = mevProtectionAllowed
        self.approval = approval

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

    override public var canSwap: Bool {
        super.canSwap && gasPrice != nil && evmFeeData != nil && transactionData != nil
    }

    override public func executable(tokenIn: Token) -> ISwapExecutable {
        EvmExecutable(
            token: tokenIn,
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: evmFeeData?.surchargedGasLimit,
            nonce: nonce,
            mevProtectionAllowed: mevProtectionAllowed,
            approval: approval
        )
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        EvmSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override public func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
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
