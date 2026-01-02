import EvmKit
import Foundation
import MarketKit

class EvmSwapFinalQuote: BaseSendEvmData, ISwapFinalQuote {
    private let expectedBuyAmount: Decimal
    let transactionData: TransactionData?
    private let transactionError: Error?
    private let slippage: Decimal?
    private let recipient: String?

    init(
        expectedBuyAmount: Decimal,
        transactionData: TransactionData?,
        transactionError: Error? = nil,
        slippage: Decimal?,
        recipient: String?,
        gasPrice: GasPrice?,
        evmFeeData: EvmFeeData?,
        nonce: Int?
    ) {
        self.expectedBuyAmount = expectedBuyAmount
        self.transactionData = transactionData
        self.transactionError = transactionError
        self.slippage = slippage
        self.recipient = recipient

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    var amountOut: Decimal {
        expectedBuyAmount
    }

    var feeData: FeeData? {
        evmFeeData.map { .evm(evmFeeData: $0) }
    }

    var canSwap: Bool {
        gasPrice != nil && evmFeeData != nil && transactionData != nil && transactionError == nil
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
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
