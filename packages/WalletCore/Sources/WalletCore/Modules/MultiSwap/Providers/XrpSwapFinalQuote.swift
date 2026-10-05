import Foundation
import MarketKit

class XrpSwapFinalQuote: SwapFinalQuote {
    private let token: Token
    private let address: String
    private let amount: Decimal
    private let destinationTag: UInt32?
    private let fee: Decimal?

    init(
        token: Token,
        address: String,
        amount: Decimal,
        destinationTag: UInt32?,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.token = token
        self.address = address
        self.amount = amount
        self.destinationTag = destinationTag
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

    override func executable(tokenIn: Token) -> ISwapExecutable {
        XrpExecutable(token: tokenIn, address: address, amount: amount, destinationTag: destinationTag)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        XrpSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        XrpSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }

    // The provider matches the deposit by this field, so it belongs on the confirmation beside the
    // deposit address, where the memo-carrying chains show their memo (Android `DataFieldDestinationTag`).
    override public func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if let destinationTag {
            fields.append(.simpleValue(title: "send.xrp.destination_tag".localized, value: String(destinationTag)))
        }

        return fields
    }
}
