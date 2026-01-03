import BitcoinCore
import Foundation
import MarketKit

class UtxoSwapFinalQuote: ISwapFinalQuote {
    private let expectedBuyAmount: Decimal
    let sendParameters: SendParameters?
    private let slippage: Decimal
    private let recipient: String?
    private let transactionError: Error?
    private let fee: Decimal?

    init(
        expectedBuyAmount: Decimal,
        sendParameters: SendParameters?,
        slippage: Decimal,
        recipient: String?,
        transactionError: Error?,
        fee: Decimal?,
    ) {
        self.expectedBuyAmount = expectedBuyAmount
        self.sendParameters = sendParameters
        self.slippage = slippage
        self.recipient = recipient
        self.transactionError = transactionError
        self.fee = fee
    }

    var amountOut: Decimal {
        expectedBuyAmount
    }

    var feeData: FeeData? {
        sendParameters.map { .bitcoin(params: $0) }
    }

    var canSwap: Bool {
        fee != nil && sendParameters != nil && transactionError == nil
    }

    func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        if let transactionError {
            return [UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
        } else {
            return []
        }
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        let minAmountOut = amountOut * (1 - slippage / 100)
        if let minRecieve = SendField.minRecieve(token: tokenOut, value: minAmountOut) {
            fields.append(minRecieve)
        }

        if let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient {
            fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
        }

        fields.append(contentsOf: UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
