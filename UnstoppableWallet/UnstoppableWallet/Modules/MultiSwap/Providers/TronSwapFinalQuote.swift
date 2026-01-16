
import EvmKit
import Foundation
import MarketKit
import TronKit

class TronSwapFinalQuote: ISwapFinalQuote {
    private let amountIn: Decimal
    private let expectedAmountOut: Decimal
    private let recipient: String?
    private let slippage: Decimal?
    let createdTransaction: CreatedTransactionResponse
    private let fees: [Fee]
    private let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: String?, slippage: Decimal?, createdTransaction: CreatedTransactionResponse, fees: [Fee], transactionError: Error?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.slippage = slippage
        self.createdTransaction = createdTransaction
        self.fees = fees
        self.transactionError = transactionError
    }

    var amountOut: Decimal {
        expectedAmountOut
    }

    var canSwap: Bool {
        transactionError == nil
    }

    var feeData: FeeData? {
        .tron(fees: fees)
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        if let transactionError {
            return [TronSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
        }

        return []
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
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

        fields.append(contentsOf: TronSendHelper.feeFields(baseToken: baseToken, totalFees: fees.calculateTotalFees(), fees: fees, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
