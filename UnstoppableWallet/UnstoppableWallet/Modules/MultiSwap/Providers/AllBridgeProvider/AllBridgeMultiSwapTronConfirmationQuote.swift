import EvmKit
import Foundation
import MarketKit
import TronKit

class AllBridgeMultiSwapTronConfirmationQuote: IMultiSwapConfirmationQuote {
    let amountIn: Decimal
    let expectedAmountOut: Decimal
    let recipient: Address?
    let crosschain: Bool
    let slippage: Decimal
    let createdTransaction: CreatedTransactionResponse
    let fees: [Fee]
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: Address?, crosschain: Bool, slippage: Decimal, createdTransaction: CreatedTransactionResponse, fees: [Fee], transactionError: Error?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.crosschain = crosschain
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
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        fields.append(contentsOf: feeFields(currency: currency, baseToken: baseToken, feeTokenRate: baseTokenRate))

        return fields
    }

    private func feeFields(currency: Currency, baseToken: Token, feeTokenRate: Decimal?) -> [SendField] {
        var viewItems = [SendField]()

        let totalFees = fees.calculateTotalFees()

        let decimalAmount = Decimal(totalFees) / pow(10, baseToken.decimals)
        let appValue = AppValue(token: baseToken, value: decimalAmount)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: decimalAmount * $0) }

        viewItems.append(
            .value(
                title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
                appValue: appValue,
                currencyValue: currencyValue,
                formatFull: true
            )
        )

        var bandwidth: String?
        var energy: String?

        for fee in fees {
            switch fee {
            case let .accountActivation(amount):
                let decimalAmount = Decimal(amount) / pow(10, baseToken.decimals)
                let appValue = AppValue(token: baseToken, value: decimalAmount)
                let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: decimalAmount * $0) }

                let info = InfoDescription(title: "tron.send.activation_fee".localized, description: "tron.send.activation_fee.info".localized)

                viewItems.append(
                    .value(
                        title: SendField.InformedTitle("tron.send.activation_fee".localized, info: info),
                        appValue: appValue,
                        currencyValue: currencyValue,
                        formatFull: true
                    )
                )

            case let .bandwidth(points, _):
                bandwidth = ValueFormatter.instance.formatShort(value: Decimal(points), decimalCount: 0)

            case let .energy(required, _):
                energy = ValueFormatter.instance.formatShort(value: Decimal(required), decimalCount: 0)
            }
        }

        if bandwidth != nil || energy != nil {
            viewItems.append(
                .doubleValue(
                    title: "tron.send.resources_consumed".localized,
                    description: .init(title: "tron.send.resources_consumed".localized, description: "tron.send.resources_consumed.info".localized),
                    value1: bandwidth.flatMap { "\($0) \("tron.send.bandwidth".localized)" } ?? "",
                    value2: energy.flatMap { "\($0) \("tron.send.energy".localized)" }
                )
            )
        }
        return viewItems
    }

    private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if case let TronSendHandler.TransactionError.insufficientBalance(balance: balance) = transactionError.convertedError {
            let appValue = AppValue(token: feeToken, value: balance.toDecimal(decimals: feeToken.decimals) ?? 0)
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
