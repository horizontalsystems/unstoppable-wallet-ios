import Foundation
import MarketKit

class StellarSwapFinalQuote: ISwapFinalQuote {
    private let amountIn: Decimal
    private let expectedAmountOut: Decimal
    private let recipient: String?
    private let crosschain: Bool
    private let slippage: Decimal
    let transactionEnvelope: String
    private let fee: Decimal?
    private let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: String?, crosschain: Bool, slippage: Decimal, transactionEnvelope: String, fee: Decimal?, transactionError: Error?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.crosschain = crosschain
        self.slippage = slippage
        self.transactionEnvelope = transactionEnvelope
        self.fee = fee
        self.transactionError = transactionError
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
        if let transactionError {
            return [caution(transactionError: transactionError, feeToken: baseToken)]
        }

        return []
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if !crosschain, let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient {
            fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
        }

        // We can use utxo fee fields because it's same parameters.
        fields.append(contentsOf: UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }

    private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if case let StellarSendHandler.TransactionError.insufficientStellarBalance(balance: balance) = transactionError.convertedError {
            let appValue = AppValue(token: feeToken, value: balance)
            let balanceString = appValue.formattedShort()

            title = "fee_settings.errors.insufficient_balance".localized
            text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? feeToken.coin.code)
        } else {
            title = "fee_settings.errors.unexpected_error".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }
}
