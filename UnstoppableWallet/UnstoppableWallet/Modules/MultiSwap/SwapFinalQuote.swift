import Foundation
import MarketKit

class SwapFinalQuote {
    private let expectedBuyAmount: Decimal
    private let slippage: Decimal?
    private let recipient: String?
    private let transactionError: Error?

    init(
        expectedBuyAmount: Decimal,
        slippage: Decimal?,
        recipient: String?,
        transactionError: Error?,
    ) {
        self.expectedBuyAmount = expectedBuyAmount
        self.slippage = slippage
        self.recipient = recipient
        self.transactionError = transactionError
    }

    var amountOut: Decimal {
        expectedBuyAmount
    }

    var feeData: FeeData? {
        nil
    }

    var canSwap: Bool {
        transactionError == nil
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let transactionError, let caution = caution(transactionError: transactionError, baseToken: baseToken) {
            cautions.append(caution)
        }

        return cautions
    }

    func caution(transactionError _: Error, baseToken _: Token) -> CautionNew? {
        nil
    }

    func fields(tokenIn _: Token, tokenOut: Token, baseToken _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate _: Decimal?) -> [SendField] {
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

        return fields
    }
}
