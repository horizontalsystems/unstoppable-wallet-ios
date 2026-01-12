import Foundation
import MarketKit
import MoneroKit

class MoneroSendHelper {
    // UI part

    static func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let moneroError = transactionError as? MoneroCoreError {
            switch moneroError {
            case let .insufficientFunds(balance):
                let appValue = AppValue(token: feeToken, value: Decimal(string: balance) ?? 0)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
            default:
                title = "ethereum_transaction.error.title".localized
                text = transactionError.convertedError.smartDescription
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    static func feeFields(
        fee: Decimal?,
        feeToken: Token,
        currency: Currency,
        feeTokenRate: Decimal?,
        priority: SendPriority
    ) -> [SendField] {
        guard let fee else { return [] }

        let appValue = AppValue(token: feeToken, value: fee)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

        var fields = [SendField]()

        if priority != .default {
            fields.append(contentsOf: [
                .levelValue(
                    title: "monero.priority".localized,
                    value: priority.description,
                    level: priority.level
                ),
            ])
        }

        return fields + [
            .value(
                title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
                appValue: appValue,
                currencyValue: currencyValue,
                formatFull: true
            ),
        ]
    }
}
