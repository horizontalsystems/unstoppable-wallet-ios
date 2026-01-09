import Foundation
import MarketKit

class StellarSwapFinalQuote: ISwapFinalQuote {
    private let amountIn: Decimal
    private let expectedAmountOut: Decimal
    private let recipient: String?
    private let slippage: Decimal?
    let transactionData: StellarSendHelper.TransactionData
    private let token: Token
    private let fee: Decimal?
    private let transactionError: Error?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        transactionData: StellarSendHelper.TransactionData,
        token: Token,
        fee: Decimal?,
        transactionError: Error?
    ) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.slippage = slippage
        self.transactionData = transactionData
        self.token = token
        self.fee = fee
        self.transactionError = transactionError

        switch transactionData {
        case let .envelope(str): print(str)
        case let .payment(asset: asset, amount: amount, accountId: account, memo: memo): print("AMOUNT: \(amount.description) | aacount: \(account) | memo: \(memo)")
        }
    }

    var amountOut: Decimal {
        expectedAmountOut
    }

    var canSwap: Bool {
        transactionError == nil
    }

    var feeData: FeeData? {
        nil
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        guard let transactionError else {
            return []
        }

        return [StellarSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
    }

    func fields(
        tokenIn _: MarketKit.Token,
        tokenOut: MarketKit.Token,
        baseToken: MarketKit.Token,
        currency: Currency,
        tokenInRate _: Decimal?,
        tokenOutRate _: Decimal?,
        baseTokenRate: Decimal?
    ) -> [SendField] {
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

        fields.append(contentsOf: StellarSendHelper.feeFields(
            fee: fee,
            feeToken: baseToken,
            currency: currency,
            feeTokenRate: baseTokenRate
        ))

        return fields
    }
}
