import EvmKit
import Foundation
import MarketKit

class EvmSwapFinalQuote: BaseSendEvmData, IMultiSwapConfirmationQuote {
    private let expectedBuyAmount: Decimal
    let transactionData: TransactionData?
    private let transactionError: Error?
    private let slippage: Decimal?
    private let recipient: String?
    private let insufficientFeeBalance: Bool

    init(
        expectedBuyAmount: Decimal,
        transactionData: TransactionData?,
        transactionError: Error? = nil,
        slippage: Decimal?,
        recipient: String?,
        insufficientFeeBalance: Bool,
        gasPrice: GasPrice?,
        evmFeeData: EvmFeeData?,
        nonce: Int?
    ) {
        self.expectedBuyAmount = expectedBuyAmount
        self.transactionData = transactionData
        self.transactionError = transactionError
        self.slippage = slippage
        self.recipient = recipient
        self.insufficientFeeBalance = insufficientFeeBalance

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    var amountOut: Decimal {
        expectedBuyAmount
    }

    var feeData: FeeData? {
        evmFeeData.map { .evm(evmFeeData: $0) }
    }

    var canSwap: Bool {
        gasPrice != nil && evmFeeData != nil && !insufficientFeeBalance && transactionData != nil
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
        }

        if insufficientFeeBalance {
            cautions.append(
                .init(
                    title: "fee_settings.errors.insufficient_balance".localized,
                    text: "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseToken.coin.code),
                    type: .error
                )
            )
        }

        return cautions
    }

    func fields(tokenIn _: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let slippage {
            let minAmountOut = amountOut * (1 - slippage / 100)
            if let minRecieve = SendField.minRecieve(token: tokenOut, value: minAmountOut) {
                fields.append(minRecieve)
            }

            if let slippage = SendField.slippage(slippage) {
                fields.append(slippage)
            }
        }

        if let recipient {
            fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
        }

        if let nonce {
            fields.append(
                .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
            )
        }

        fields.append(contentsOf: feeFields(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
