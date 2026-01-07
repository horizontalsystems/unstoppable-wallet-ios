import Foundation
import MarketKit
import TonKit

class TonSwapFinalQuote: ISwapFinalQuote {
    private let amountIn: Decimal
    private let expectedAmountOut: Decimal
    private let recipient: String?
    private let slippage: Decimal
    let transactionParam: SendTransactionParam
    private let fee: Decimal?
    private let transactionError: Error?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal,
        transactionParam: SendTransactionParam,
        fee: Decimal?,
        transactionError: Error?,
    ) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.slippage = slippage
        self.transactionParam = transactionParam
        self.fee = fee
        self.transactionError = transactionError
    }

    var amountOut: Decimal {
        expectedAmountOut
    }

    var canSwap: Bool {
        transactionError == nil && fee != nil
    }

    var feeData: FeeData? {
        nil
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        if let transactionError {
            return [TonSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
        }

        return []
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient {
            fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
        }

        fields.append(contentsOf: TonSendHelper.feeFields(
            fee: fee,
            feeToken: baseToken,
            currency: currency,
            feeTokenRate: baseTokenRate
        ))

        return fields
    }
}
