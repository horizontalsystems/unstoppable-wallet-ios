import EvmKit
import Foundation
import MarketKit
import TronKit

class AllBridgeMultiSwapStellarConfirmationQuote: IMultiSwapConfirmationQuote {
    let amountIn: Decimal
    let expectedAmountOut: Decimal
    let recipient: Address?
    let crosschain: Bool
    let slippage: Decimal
    let transactionEnvelope: String
    let fee: Decimal?
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: Address?, crosschain: Bool, slippage: Decimal, transactionEnvelope: String, fee: Decimal?, transactionError: Error?) {
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

    func priceSectionFields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken _: MarketKit.Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate _: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        if !crosschain {
            fields.append(.slippage(slippage))
        }

        return fields
    }

    func otherSections(tokenIn _: Token, tokenOut _: Token, baseToken: Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendDataSection] {
        [.init(feeFields(currency: currency, baseToken: baseToken, feeTokenRate: baseTokenRate))]
    }

    private func feeFields(currency: Currency, baseToken: Token, feeTokenRate: Decimal?) -> [SendField] {
        var viewItems = [SendField]()

        guard let fee else {
            return []
        }

        let appValue = AppValue(token: baseToken, value: fee)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

        viewItems.append(
            .value(
                title: "fee_settings.network_fee".localized,
                description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                appValue: appValue,
                currencyValue: currencyValue,
                formatFull: true
            )
        )

        return viewItems
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
